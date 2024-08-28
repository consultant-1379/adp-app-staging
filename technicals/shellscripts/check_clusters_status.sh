#!/usr/bin/env bash

for cluster_info_file in product_ci_cluster_infos/*.info
do
  sed -i "s/'//g" "${cluster_info_file}"
  sed -i 's/\[//; s/\]// ; s/\\n,/\n/g; s/\\n/\n/g; s/,/\n/g' "${cluster_info_file}"
  sed -i 's/^[[:space:]]//g' "${cluster_info_file}"
done

mapfile -t HEALTH_WARN_clusters < <(find product_ci_cluster_infos/cluster_*.info -exec  grep -rl 'HEALTH_WARN'  {} \;)
mapfile -t HEALTH_ERR_clusters < <(find product_ci_cluster_infos/cluster_*.info -exec  grep -rl 'HEALTH_ERR'  {} \;)
mapfile -t NotReady_clusters < <(find product_ci_cluster_infos/cluster_*.info -exec  grep -rl 'NotReady'  {} \;)

# shellcheck disable=SC2128
if [ -n "$HEALTH_ERR_clusters" ]
then
  echo "We have HEALTH_ERR state on our cluster(s) rook-ceph" > clusters.status
  echo "────────────────────────────────────────────────────" >> clusters.status
  for HEALTH_ERR_cluster in "${HEALTH_ERR_clusters[@]}"
  do
    < "${HEALTH_ERR_cluster}" grep 'cluster_ci\|HEALTH_ERR' >> clusters.status
    echo "────────────────────────────────────────────────────" >> clusters.status
  done
fi

# shellcheck disable=SC2128
if [ -n "$HEALTH_WARN_clusters" ]
then
  if [ -f clusters.status ]; then
    echo "" >> clusters.status
  fi
  echo "We have HEALTH_WARN state on our cluster(s) rook-ceph" >> clusters.status
  echo "────────────────────────────────────────────────────" >> clusters.status
  for HEALTH_WARN_cluster in "${HEALTH_WARN_clusters[@]}"
  do
    < "${HEALTH_WARN_cluster}" grep 'cluster_ci\|HEALTH_WARN' >> clusters.status
    echo "────────────────────────────────────────────────────" >> clusters.status
  done
fi

# shellcheck disable=SC2128
if [ -n "$NotReady_clusters" ]
then
  if [ -f clusters.status ]; then
    echo "" >> clusters.status
  fi
  echo "We have some worker NotReady state on our cluster(s)" > clusters.status
  echo "────────────────────────────────────────────────────" >> clusters.status
  for NotReady_cluster in "${NotReady_clusters[@]}"
  do
    < "${NotReady_cluster}" grep 'cluster_ci\|NotReady' >> clusters.status
    echo "────────────────────────────────────────────────────" >> clusters.status
  done
fi
