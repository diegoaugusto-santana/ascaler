#!/bin/bash
# external variables
LOOP=${LOOP:='yes'}
# limits and target are % of each replica's CPU limit
CPU_UPPER_LIMIT=${CPU_UPPER_LIMIT:=85}
CPU_LOWER_LIMIT=${CPU_LOWER_LIMIT:=25}
CPU_TARGET=${CPU_TARGET:=60}
CPU_WINDOW_UP=${CPU_WINDOW_UP:=30s}
CPU_WINDOW_DOWN=${CPU_WINDOW_DOWN:=2m}
MAX_DOWN_STEP=${MAX_DOWN_STEP:=2}
PROMETHEUS_URL=${PROMETHEUS_URL:=http://apps6.local:9090}

##wait time WITH units 3600s 60m 1h
WAIT_TIME=${WAIT_TIME:=60s}

# internal variables

PROMETHEUS_API="api/v1/query?query="

## return name, minimum, maximum, replicas and cpu limit (nanocpus)
## of every service with the label "ascaler=true"
## ================================================================
get_svc_ascaler() {
    local services=$(docker service inspect $(docker service ls -q) | jq  '[.[] | select(.Spec.Labels["ascaler"]=="true")| [ .Spec.Name, .Spec.Labels["ascaler.minimum"], .Spec.Labels["ascaler.maximum"], .Spec.Mode.Replicated.Replicas, (.Spec.TaskTemplate.Resources.Limits.NanoCPUs // 0) ] ] ')
    echo $services
}

## return the cpu of the service (param $1) over the window (param $2)
## as % of one core, summed over replicas, or "nodata"
## ================================================================
get_svc_metrics() {
  local SVC=$1
  local WINDOW=$2
  local PQUERY=sum%28rate%28container_cpu_usage_seconds_total%7Bcontainer_label_com_docker_swarm_service_name%3D%22$SVC%22%7D%5B$WINDOW%5D%29%20%29%2A100
  local value=$(curl --silent "${PROMETHEUS_URL}/${PROMETHEUS_API}${PQUERY}" | jq -r '.data.result[0].value[1]')
  # at startup or if not present Prometheus send a null value
  if [ -z "$value" ] || [ "$value" = "null" ]; then
    value=nodata
  fi
  echo $value
}

## cpu used as % of the limit of all replicas
## param: sum of cpu, replicas, limit in cores
utilization() {
  awk -v s="$1" -v r="$2" -v l="$3" 'BEGIN{printf "%.2f", s/(r*l)}'
}

## replicas needed to bring the utilization back to the target
## param: replicas, utilization
desired() {
  awk -v r="$1" -v u="$2" -v t="$CPU_TARGET" 'BEGIN{d=r*u/t; c=int(d); if(c<d)c++; print c}'
}

## param: value, limit
above() { awk -v a="$1" -v b="$2" 'BEGIN{exit !(a > b)}'; }
below() { awk -v a="$1" -v b="$2" 'BEGIN{exit !(a < b)}'; }

## scale to new value
## param 1 : services
## param 2 : new repl value
scale() {
  docker service scale -d $1=$2 >>/dev/null
  echo "INFO:  $1 scaled to $2 replicas"
}

check () {
  # get services
  assvcs=$(get_svc_ascaler)
  echo "Service to survey"
  echo $assvcs
  items=$(echo "$assvcs" | jq -c -r '.[]')
  for item in ${items[@]}; do
      ## split data
      local  svc=$(echo "$item" | jq -c -r '.[0]')
      local  min=$(echo "$item" | jq -c -r '.[1]')
      local  max=$(echo "$item" | jq -c -r '.[2]')
      local repl=$(echo "$item" | jq -c -r '.[3]')
      local nano=$(echo "$item" | jq -c -r '.[4]')
      echo check $svc

      ## set default replicas (min or max)
      if [ "$repl" -lt "$min" ]; then
        scale $svc $min
        repl=$min
      elif [ "$repl" -gt "$max" ]; then
        scale $svc $max
        repl=$max
      fi

      ## a replica without cpu limit counts as one core
      local limit=$(awk -v n="$nano" 'BEGIN{if(n>0) print n/1000000000; else print 1}')

      ## get metrics
      local sum_up=$(get_svc_metrics $svc $CPU_WINDOW_UP)
      local sum_down=$(get_svc_metrics $svc $CPU_WINDOW_DOWN)
      if [ "$sum_up" = "nodata" ] || [ "$sum_down" = "nodata" ]; then
        echo "WARNING: $svc no metrics, skipping"
        continue
      fi

      local util_up=$(utilization $sum_up $repl $limit)
      local util_down=$(utilization $sum_down $repl $limit)
      echo "METRIC: $svc util_up=$util_up% util_down=$util_down% repl=$repl min=$min max=$max"

      ## scale up first: fast window, as many replicas as needed
      if above $util_up $CPU_UPPER_LIMIT; then
        local newrepl=$(desired $repl $util_up)
        [ "$newrepl" -le "$repl" ] && newrepl=$(( repl+1 ))
        if [ "$repl" -ge "$max" ]; then
          echo "WARNING: $svc need more replica than authorized"
        else
          [ "$newrepl" -gt "$max" ] && newrepl=$max
          scale $svc $newrepl
        fi
      ## scale down: slow window, limited step
      elif below $util_down $CPU_LOWER_LIMIT && below $util_up $CPU_LOWER_LIMIT; then
        local newrepl=$(desired $repl $util_down)
        local floor=$(( repl-MAX_DOWN_STEP ))
        [ "$newrepl" -lt "$floor" ] && newrepl=$floor
        [ "$newrepl" -lt "$min" ] && newrepl=$min
        if [ "$newrepl" -lt "$repl" ]; then
          scale $svc $newrepl
        fi
      fi
  done
}

## Main loop
echo "****************************************************************************"
echo "**  ASCALER V1.00                                                         **"
echo "**  A Docker Swarm Simple Scaler                                          **"
echo "**                                                                        **"
echo "**  Base Idea : docker-swarm-autoscaler                                   **"
echo "**  Rewrite by Unclephil                                                  **"
echo "**  sources: https://github.com/UnclePhil/ascaler                         **"
echo "**                                                                        **"
echo "****************************************************************************"

check
while [[ $LOOP == 'yes' ]]; do
  echo "Waiting $WAIT_TIME"
  sleep $WAIT_TIME
  check
done
