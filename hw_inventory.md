# EEA4 Product CI Inventory

**Table of contents:**
<!-- START doctoc
...
END doctoc -->

## Clusters

[Product CI clusters Excel](https://ericsson.sharepoint.com/:x:/r/sites/EEA4CI/Shared%20Documents/General/Product%20CI%20clusters.xlsx?d=we86a49c777a84b189b6d082e815f40ff&csf=1&web=1&e=p5RoJT)

[Product CI cluster info page](https://seliius27190.seli.gic.ericsson.se:8443/job/EEA4-cluster-info-collector/Product_5fCI_5fcluster_5finfos/)

Information below is gathered by running `cluster_tools/generate_cluster_inventory_md.sh` on the cluster's master node.

| Cluster name | Role                      |   Hostname      |   IP address   | CPU |  MEM  | HDD                                                                                        |
|--------------|---------------------------|-----------------|----------------|-----|-------|--------------------------------------------------------------------------------------------|
| seliics04041 | control-plane, worker     | seliics04041e01 | 10.196.123.229 | 40  | 314.5 | sda: 2,18TiB,sdb: 2,18TiB,sdc: 2,18TiB                                                     |
| VRID:51      | worker                    | seliics04041e02 | 10.196.123.231 | 40  | 314.5 | sda:2,18TiB,sdb:2,18TiB,sdc:2,18TiB                                                        |
|              | worker                    | seliics04042e01 | 10.196.124.5   | 40  | 314.5 | sda:2,18TiB,sdb:2,18TiB,sdc:2,18TiB                                                        |
|              | worker                    | seliics04042e02 | 10.196.124.7   | 40  | 314.5 | sda:2,18TiB,sdb:2,18TiB,sdc:2,18TiB                                                        |
|              | Traffic Ingestion Network | seliics04041e04 | 10.196.123.233 |     |       |                                                                                            |
|              | Traffic Ingestion Network | seliics04041e05 | 10.196.123.235 |     |       |                                                                                            |
|              | Traffic Ingestion Network | seliics04041e06 | 10.196.123.236 |     |       |                                                                                            |
|              | Analytics Data Network    | seliics04041e07 | 10.196.123.247 |     |       |                                                                                            |
|              | Reference Data Network    | seliics04041e08 | 10.196.123.255 |     |       |                                                                                            |
|              | OAM Network               | seliics04041e09 | 10.196.124.0   |     |       |                                                                                            |
|              | OAM Network               | seliics04041e10 | 10.196.124.4   |     |       |                                                                                            |
|              | for additional uses       | seliics04041e03 | 10.196.123.232 |     |       |                                                                                            |

| Cluster name | Role                      |   Hostname      |   IP address   | CPU |  MEM  | HDD                                                                                        |
|--------------|---------------------------|-----------------|----------------|-----|-------|--------------------------------------------------------------------------------------------|
| seliics04493 | control-plane, worker     | seliics04493e01 | 10.196.124.164 | 40  | 314.5 | sda: 2,18TiB,sdb: 2,18TiB,sdc: 2,18TiB                                                     |
| VRID:51      | worker                    | seliics04493e02 | 10.196.124.165 | 40  | 314.5 | sda:2,18TiB,sdb:2,18TiB,sdc:2,18TiB                                                        |
|              | worker                    | seliics04538e01 | 10.196.124.76  | 40  | 314.5 | sda:2,18TiB,sdb:2,18TiB,sdc:2,18TiB                                                        |
|              | worker                    | seliics04538e02 | 10.196.122.147 | 40  | 314.5 | sda:2,18TiB,sdb:2,18TiB,sdc:2,18TiB                                                        |
|              | Traffic Ingestion Network | seliics04493e04 | 10.196.124.166 |     |       |                                                                                            |
|              | Traffic Ingestion Network | seliics04493e05 | 10.196.124.167 |     |       |                                                                                            |
|              | Traffic Ingestion Network | seliics04493e06 | 10.196.124.168 |     |       |                                                                                            |
|              | Analytics Data Network    | seliics04493e07 | 10.196.124.169 |     |       |                                                                                            |
|              | Reference Data Network    | seliics04493e08 | 10.196.124.170 |     |       |                                                                                            |
|              | OAM Network               | seliics04493e09 | 10.196.124.171 |     |       |                                                                                            |
|              | OAM Network               | seliics04493e10 | 10.196.124.174 |     |       |                                                                                            |
|              | for additional uses       | seliics04493e03 | 10.196.123.208 |     |       |                                                                                            |

| Cluster name | Role                      |   Hostname      |   IP address   | CPU |  MEM  | HDD                                                                                        |
|--------------|---------------------------|-----------------|----------------|-----|-------|--------------------------------------------------------------------------------------------|
| seliics04501 | control-plane, worker     | seliics04501e01 | 10.196.123.239 | 40  | 314.9 | sda: 2,18TiB,sdb: 2,18TiB,sdc: 2,18TiB                                                     |
| VRID:51      | worker                    | seliics04501e02 | 10.196.123.240 | 40  | 314.9 | sda:2,18TiB,sdb:2,18TiB,sdc:2,18TiB                                                        |
|              | worker                    | seliics04502e01 | 10.196.123.245 | 40  | 314.9 | sda:2,18TiB,sdb:2,18TiB,sdc:2,18TiB                                                        |
|              | worker                    | seliics04502e02 | 10.196.123.246 | 40  | 314.9 | sda:2,18TiB,sdb:2,18TiB,sdc:2,18TiB                                                        |
|              | Traffic Ingestion Network | seliics04501e04 | 10.196.123.242 |     |       |                                                                                            |
|              | Traffic Ingestion Network | seliics04501e05 | 10.196.123.243 |     |       |                                                                                            |
|              | Traffic Ingestion Network | seliics04501e06 | 10.196.121.43  |     |       |                                                                                            |
|              | Analytics Data Network    | seliics04501e07 | 10.196.121.48  |     |       |                                                                                            |
|              | Reference Data Network    | seliics04501e08 | 10.196.121.49  |     |       |                                                                                            |
|              | OAM Network               | seliics04501e09 | 10.196.121.50  |     |       |                                                                                            |
|              | OAM Network               | seliics04501e10 | 10.196.121.51  |     |       |                                                                                            |
|              | for additional uses       | seliics04501e03 | 10.196.123.241 |     |       |                                                                                            |

| Cluster name | Role                      |   Hostname      |   IP address   | CPU |  MEM  | HDD                                                                                        |
|--------------|---------------------------|-----------------|----------------|-----|-------|--------------------------------------------------------------------------------------------|
| seliics04503 | control-plane, worker     | seliics04503e01 | 10.196.123.249 | 40  | 314.9 | sda: 2,18TiB,sdb: 2,18TiB,sdc: 2,18TiB                                                     |
| VRID:51      | worker                    | seliics04503e02 | 10.196.123.250 | 40  | 314.9 | sda:2,18TiB,sdb:2,18TiB,sdc:2,18TiB                                                        |
|              | worker                    | seliics04504e01 | 10.196.123.253 | 40  | 314.9 | sda:2,18TiB,sdb:2,18TiB,sdc:2,18TiB                                                        |
|              | worker                    | seliics04504e02 | 10.196.123.254 | 40  | 314.9 | sda:2,18TiB,sdb:2,18TiB,sdc:2,18TiB                                                        |
|              | Traffic Ingestion Network | seliics04503e04 | 10.196.121.52  |     |       |                                                                                            |
|              | Traffic Ingestion Network | seliics04503e05 | 10.196.121.54  |     |       |                                                                                            |
|              | Traffic Ingestion Network | seliics04503e06 | 10.196.121.97  |     |       |                                                                                            |
|              | Analytics Data Network    | seliics04503e07 | 10.196.121.180 |     |       |                                                                                            |
|              | Reference Data Network    | seliics04503e08 | 10.196.122.87  |     |       |                                                                                            |
|              | OAM Network               | seliics04503e09 | 10.196.122.88  |     |       |                                                                                            |
|              | OAM Network               | seliics04503e10 | 10.196.122.89  |     |       |                                                                                            |
|              | for additional uses       | seliics04503e03 | 10.196.123.251 |     |       |                                                                                            |

| Cluster name | Role                      |   Hostname      |   IP address   | CPU |  MEM  | HDD                                                                                        |
|--------------|---------------------------|-----------------|----------------|-----|-------|--------------------------------------------------------------------------------------------|
| seliics04510 | control-plane, worker     | seliics04510e01 | 10.196.122.166 | 40  | 314.5 | sda: 2,18TiB,sdb: 2,18TiB,sdc: 2,18TiB                                                     |
| VRID:51      | worker                    | seliics04497e01 | 10.196.122.163 | 40  | 314.5 | sda:2,18TiB,sdb:2,18TiB,sdc:2,18TiB                                                        |
|              | worker                    | seliics04497e02 | 10.196.122.164 | 40  | 314.5 | sda:2,18TiB,sdb:2,18TiB,sdc:2,18TiB                                                        |
|              | worker                    | seliics04510e02 | 10.196.122.167 | 40  | 314.5 | sda:2,18TiB,sdb:2,18TiB,sdc:2,18TiB                                                        |
|              | Traffic Ingestion Network | seliics04510e04 | 10.196.122.169 |     |       |                                                                                            |
|              | Traffic Ingestion Network | seliics04510e05 | 10.196.122.170 |     |       |                                                                                            |
|              | Traffic Ingestion Network | seliics04510e06 | 10.196.122.171 |     |       |                                                                                            |
|              | Analytics Data Network    | seliics04510e07 | 10.196.122.172 |     |       |                                                                                            |
|              | Reference Data Network    | seliics04510e08 | 10.196.122.173 |     |       |                                                                                            |
|              | OAM Network               | seliics04510e09 | 10.196.122.174 |     |       |                                                                                            |
|              | OAM Network               | seliics04510e10 | 10.196.123.173 |     |       |                                                                                            |
|              | for additional uses       | seliics04510e11 | 10.196.123.174 |     |       |                                                                                            |
|              | for additional uses       | seliics04510e03 | 10.196.122.168 |     |       |                                                                                            |

| Cluster name | Role                      |   Hostname      |   IP address   | CPU |  MEM  | HDD                                                                                        |
|--------------|---------------------------|-----------------|----------------|-----|-------|--------------------------------------------------------------------------------------------|
| seliics04511 | control-plane, worker     | seliics04511e01 | 10.196.122.148 | 40  | 314.5 | sda: 2,18TiB,sdb: 2,18TiB,sdc: 2,18TiB                                                     |
| VRID:51      | worker                    | seliics04511e02 | 10.196.122.161 | 40  | 314.5 | sda:2,18TiB,sdb:2,18TiB,sdc:2,18TiB                                                        |
|              | worker                    | seliics04512e01 | 10.196.122.175 | 40  | 314.5 | sda:2,18TiB,sdb:2,18TiB,sdc:2,18TiB                                                        |
|              | worker                    | seliics04512e02 | 10.196.123.14  | 40  | 314.5 | sda:2,18TiB,sdb:2,18TiB,sdc:2,18TiB                                                        |
|              | Traffic Ingestion Network | seliics04511e04 | 10.196.122.190 |     |       |                                                                                            |
|              | Traffic Ingestion Network | seliics04511e05 | 10.196.122.191 |     |       |                                                                                            |
|              | Traffic Ingestion Network | seliics04511e06 | 10.196.122.243 |     |       |                                                                                            |
|              | Analytics Data Network    | seliics04511e07 | 10.196.122.244 |     |       |                                                                                            |
|              | Reference Data Network    | seliics04511e08 | 10.196.122.245 |     |       |                                                                                            |
|              | OAM Network               | seliics04511e09 | 10.196.123.11  |     |       |                                                                                            |
|              | OAM Network               | seliics04511e10 | 10.196.123.13  |     |       |                                                                                            |
|              | for additional uses       | seliics04511e03 | 10.196.122.162 |     |       |                                                                                            |

| Cluster name | Role                      |   Hostname      |   IP address   | CPU |  MEM  | HDD                                                                                        |
|--------------|---------------------------|-----------------|----------------|-----|-------|--------------------------------------------------------------------------------------------|
| seliics04513 | control-plane, worker     | seliics04513e01 | 10.196.122.181 | 40  | 314.5 | sda: 2,18TiB,sdb: 2,18TiB,sdc: 2,18TiB                                                     |
| VRID:51      | worker                    | seliics04513e02 | 10.196.122.182 | 40  | 314.5 | sda:2,18TiB,sdb:2,18TiB,sdc:2,18TiB                                                        |
|              | worker                    | seliics04514e01 | 10.196.122.187 | 40  | 314.5 | sda:2,18TiB,sdb:2,18TiB,sdc:2,18TiB                                                        |
|              | worker                    | seliics04514e02 | 10.196.122.188 | 40  | 314.5 | sda:2,18TiB,sdb:2,18TiB,sdc:2,18TiB                                                        |
|              | Traffic Ingestion Network | seliics04513e04 | 10.196.122.184 |     |       |                                                                                            |
|              | Traffic Ingestion Network | seliics04513e05 | 10.196.122.185 |     |       |                                                                                            |
|              | Traffic Ingestion Network | seliics04513e06 | 10.196.122.186 |     |       |                                                                                            |
|              | Analytics Data Network    | seliics04513e07 | 10.196.123.209 |     |       |                                                                                            |
|              | Reference Data Network    | seliics04513e08 | 10.196.123.210 |     |       |                                                                                            |
|              | OAM Network               | seliics04513e09 | 10.196.123.211 |     |       |                                                                                            |
|              | OAM Network               | seliics04513e10 | 10.196.123.212 |     |       |                                                                                            |
|              | for additional uses       | seliics04513e11 | 10.196.123.213 |     |       |                                                                                            |
|              | for additional uses       | seliics04513e03 | 10.196.122.183 |     |       |                                                                                            |

| Cluster name | Role                      |   Hostname      |   IP address   | CPU |  MEM  | HDD                                                                                        |
|--------------|---------------------------|-----------------|----------------|-----|-------|--------------------------------------------------------------------------------------------|
| seliics04516 | control-plane, worker     | seliics04516e01 | 10.196.121.188 | 40  | 314.5 | sda: 2,18TiB,sdb: 2,18TiB,sdc: 2,18TiB                                                     |
| VRID:51      | worker                    | seliics04516e02 | 10.196.122.133 | 40  | 314.5 | sda:2,18TiB,sdb:2,18TiB,sdc:2,18TiB                                                        |
|              | worker                    | seliics04531e01 | 10.196.124.119 | 40  | 314.5 | sda:2,18TiB,sdb:2,18TiB,sdc:2,18TiB                                                        |
|              | worker                    | seliics04531e02 | 10.196.124.236 | 40  | 314.5 | sda:2,18TiB,sdb:2,18TiB,sdc:2,18TiB                                                        |
|              | Traffic Ingestion Network | seliics04516e04 | 10.196.124.229 |     |       |                                                                                            |
|              | Traffic Ingestion Network | seliics04516e05 | 10.196.124.230 |     |       |                                                                                            |
|              | Traffic Ingestion Network | seliics04516e06 | 10.196.124.231 |     |       |                                                                                            |
|              | Analytics Data Network    | seliics04516e07 | 10.196.124.232 |     |       |                                                                                            |
|              | Reference Data Network    | seliics04516e08 | 10.196.124.233 |     |       |                                                                                            |
|              | OAM Network               | seliics04516e09 | 10.196.124.234 |     |       |                                                                                            |
|              | OAM Network               | seliics04516e10 | 10.196.124.235 |     |       |                                                                                            |
|              | for additional uses       | seliics04516e03 | 10.196.124.228 |     |       |                                                                                            |

| Cluster name | Role                      |   Hostname      |   IP address   | CPU |  MEM  | HDD                                                                                        |
|--------------|---------------------------|-----------------|----------------|-----|-------|--------------------------------------------------------------------------------------------|
| seliics04518 | control-plane, worker     | seliics04518e01 | 10.196.121.186 | 40  | 314.5 | sda: 2,18TiB,sdb: 2,18TiB,sdc: 2,18TiB                                                     |
| VRID:51      | worker                    | seliics04518e02 | 10.196.122.153 | 40  | 314.5 | sda:2,18TiB,sdb:2,18TiB,sdc:2,18TiB                                                        |
|              | worker                    | seliics04519e01 | 10.196.122.159 | 40  | 314.5 | sda:2,18TiB,sdb:2,18TiB,sdc:2,18TiB                                                        |
|              | worker                    | seliics04519e02 | 10.196.122.160 | 40  | 314.5 | sda:2,18TiB,sdb:2,18TiB,sdc:2,18TiB                                                        |
|              | Traffic Ingestion Network | seliics04518e04 | 10.196.122.155 |     |       |                                                                                            |
|              | Traffic Ingestion Network | seliics04518e05 | 10.196.126.87  |     |       |                                                                                            |
|              | Traffic Ingestion Network | seliics04518e06 | 10.196.126.88  |     |       |                                                                                            |
|              | Analytics Data Network    | seliics04518e07 | 10.196.126.89  |     |       |                                                                                            |
|              | Reference Data Network    | seliics04518e08 | 10.196.126.90  |     |       |                                                                                            |
|              | OAM Network               | seliics04518e09 | 10.196.122.85  |     |       |                                                                                            |
|              | OAM Network               | seliics04518e10 | 10.196.122.99  |     |       |                                                                                            |
|              | for additional uses       | seliics04518e03 | 10.196.122.154 |     |       |                                                                                            |

| Cluster name | Role                      |   Hostname      |   IP address   | CPU |  MEM  | HDD                                                                                        |
|--------------|---------------------------|-----------------|----------------|-----|-------|--------------------------------------------------------------------------------------------|
| seliics04532 | control-plane, worker     | seliics04532e01 | 10.196.124.120 | 40  | 314.5 | sda: 2,18TiB,sdb: 2,18TiB,sdc: 2,18TiB                                                     |
| VRID:51      | worker                    | seliics04532e02 | 10.196.124.237 | 40  | 314.5 | sda:2,18TiB,sdb:2,18TiB,sdc:2,18TiB                                                        |
|              | worker                    | seliics04533e01 | 10.196.124.121 | 40  | 314.5 | sda:2,18TiB,sdb:2,18TiB,sdc:2,18TiB                                                        |
|              | worker                    | seliics04533e02 | 10.196.125.9   | 40  | 314.5 | sda:2,18TiB,sdb:2,18TiB,sdc:2,18TiB                                                        |
|              | Traffic Ingestion Network | seliics04532e04 | 10.196.124.239 |     |       |                                                                                            |
|              | Traffic Ingestion Network | seliics04532e05 | 10.196.124.240 |     |       |                                                                                            |
|              | Traffic Ingestion Network | seliics04532e06 | 10.196.125.2   |     |       |                                                                                            |
|              | Analytics Data Network    | seliics04532e07 | 10.196.125.5   |     |       |                                                                                            |
|              | Reference Data Network    | seliics04532e08 | 10.196.125.6   |     |       |                                                                                            |
|              | OAM Network               | seliics04532e09 | 10.196.125.7   |     |       |                                                                                            |
|              | OAM Network               | seliics04532e10 | 10.196.125.8   |     |       |                                                                                            |
|              | for additional uses       | seliics04532e03 | 10.196.124.238 |     |       |                                                                                            |

| Cluster name | Role                      |   Hostname      |   IP address   | CPU |  MEM  | HDD                                                                                        |
|--------------|---------------------------|-----------------|----------------|-----|-------|--------------------------------------------------------------------------------------------|
| seliics04534 | control-plane, worker     | seliics04534e01 | 10.196.120.52  | 40  | 314.9 | sda:2,18TiB,sdb:2,18TiB,sdc:2,18TiB                                                        |
| VRID:51      | worker                    | seliics04534e02 | 10.196.120.53  | 40  | 314.9 | sda:2,18TiB,sdb:2,18TiB,sdc:2,18TiB                                                        |
|              | worker                    | seliics04535e01 | 10.196.121.46  | 40  | 314.9 | sda:2,18TiB,sdb:2,18TiB,sdc:2,18TiB                                                        |
|              | worker                    | seliics04535e02 | 10.196.121.47  | 40  | 314.9 | sda:2,18TiB,sdb:2,18TiB,sdc:2,18TiB                                                        |
|              | Traffic Ingestion Network | seliics04534e04 | 10.196.120.90  |     |       |                                                                                            |
|              | Traffic Ingestion Network | seliics04534e05 | 10.196.121.44  |     |       |                                                                                            |
|              | Traffic Ingestion Network | seliics04534e06 | 10.196.120.222 |     |       |                                                                                            |
|              | Traffic Ingestion Network | seliics04534e07 | 10.196.123.144 |     |       |                                                                                            |
|              | Analytics Data Network    | seliics04534e08 | 10.196.123.145 |     |       |                                                                                            |
|              | Reference Data Network    | seliics04534e09 | 10.196.123.146 |     |       |                                                                                            |
|              | OAM Network               | seliics04534e10 | 10.196.123.147 |     |       |                                                                                            |
|              | OAM Network               | seliics04534e11 | 10.196.123.148 |     |       |                                                                                            |
|              | for additional uses       | seliics04534e03 | 10.196.120.89  |     |       |                                                                                            |
|              |                           |                 |                |     |       |                                                                                            |

| Cluster name | Role                      |   Hostname      |   IP address   | CPU |  MEM  | HDD                                                                                                                     |
|--------------|---------------------------|-----------------|----------------|-----|-------|-------------------------------------------------------------------------------------------------------------------------|
| seliics04536 | control-plane, worker     | seliics04536e01 | 10.196.122.109 | 40  | 314.9 | sda:2,18TiB,sdb:2,18TiB,sdc:2,18TiB                                                                                     |
| VRID:51      | worker                    | seliics04536e02 | 10.196.122.110 | 40  | 314.9 | sda:2,18TiB,sdb:2,18TiB,sdc:2,18TiB                                                                                     |
|              | worker                    | seliics04537e01 | 10.196.120.149 | 40  | 314.9 | sda:2,18TiB,sdb:2,18TiB,sdc:2,18TiB                                                                                     |
|              | worker                    | seliics04537e02 | 10.196.120.220 | 40  | 314.9 | sda:2,18TiB,sdb:2,18TiB,sdc:2,18TiB                                                                                     |
|              | Traffic Ingestion Network | seliics04536e04 | 10.196.120.118 |     |       |                                                                                                                         |
|              | Traffic Ingestion Network | seliics04536e05 | 10.196.120.119 |     |       |                                                                                                                         |
|              | Traffic Ingestion Network | seliics04536e06 | 10.196.120.135 |     |       |                                                                                                                         |
|              | Analytics Data Network    | seliics04536e07 | 10.196.120.139 |     |       |                                                                                                                         |
|              | Reference Data Network    | seliics04536e08 | 10.196.120.140 |     |       |                                                                                                                         |
|              | OAM Network               | seliics04536e09 | 10.196.120.141 |     |       |                                                                                                                         |
|              | OAM Network               | seliics04536e10 | 10.196.120.142 |     |       |                                                                                                                         |
|              | for additional uses       | seliics04536e03 | 10.196.120.72  |     |       |                                                                                                                         |
|              |                           |                 |                |     |       |                                                                                                                         |

| Cluster name | Role                      |   Hostname      |   IP address   | CPU |  MEM  | HDD                                                                                        |
|--------------|---------------------------|-----------------|----------------|-----|-------|--------------------------------------------------------------------------------------------|
| seliics04539 | control-plane, worker     | seliics04539e01 | 10.196.124.80  | 40  | 314.9 | sda: 2,18TiB,sdb: 2,18TiB,sdc: 2,18TiB                                                     |
| VRID:51      | worker                    | seliics04539e02 | 10.196.124.81  | 40  | 314.9 | sda:2,18TiB,sdb:2,18TiB,sdc:2,18TiB                                                        |
|              | worker                    | seliics04542e01 | 10.196.120.6   | 40  | 314.9 | sda:2,18TiB,sdb:2,18TiB,sdc:2,18TiB                                                        |
|              | worker                    | seliics04542e02 | 10.196.121.3   | 40  | 314.9 | sda:2,18TiB,sdb:2,18TiB,sdc:2,18TiB                                                        |
|              | Traffic Ingestion Network | seliics04539e04 | 10.196.121.4   |     |       |                                                                                            |
|              | Traffic Ingestion Network | seliics04539e05 | 10.196.121.10  |     |       |                                                                                            |
|              | Traffic Ingestion Network | seliics04539e06 | 10.196.121.12  |     |       |                                                                                            |
|              | Analytics Data Network    | seliics04539e07 | 10.196.121.37  |     |       |                                                                                            |
|              | Reference Data Network    | seliics04539e08 | 10.196.121.39  |     |       |                                                                                            |
|              | OAM Network               | seliics04539e09 | 10.196.121.53  |     |       |                                                                                            |
|              | OAM Network               | seliics04539e10 | 10.196.121.77  |     |       |                                                                                            |
|              | for additional uses       | seliics04539e03 | 10.196.121.45  |     |       |                                                                                            |

| Cluster name | Role                      |   Hostname      |   IP address   | CPU |  MEM  | HDD                                                                                        |
|--------------|---------------------------|-----------------|----------------|-----|-------|--------------------------------------------------------------------------------------------|
| seliics07837 | control-plane, worker     | seliics07837e01 | 10.196.120.137 | 40  | 314.9 | sda: 2,18TiB,sdb: 2,18TiB,sdc: 2,18TiB                                                     |
| VRID:51      | worker                    | seliics07837e02 | 10.196.120.201 | 40  | 314.9 | sda:2,18TiB,sdb:2,18TiB,sdc:2,18TiB                                                        |
|              | worker                    | seliics07838e01 | 10.196.120.202 | 40  | 314.9 | sda:2,18TiB,sdb:2,18TiB,sdc:2,18TiB                                                        |
|              | worker                    | seliics07838e02 | 10.196.120.203 | 40  | 314.9 | sda:2,18TiB,sdb:2,18TiB,sdc:2,18TiB                                                        |
|              | Traffic Ingestion Network | seliics07837e04 | 10.196.120.71  |     |       |                                                                                            |
|              | Traffic Ingestion Network | seliics07837e05 | 10.196.120.106 |     |       |                                                                                            |
|              | Traffic Ingestion Network | seliics07837e06 | 10.196.120.124 |     |       |                                                                                            |
|              | Analytics Data Network    | seliics07837e07 | 10.196.120.125 |     |       |                                                                                            |
|              | Reference Data Network    | seliics07837e08 | 10.196.120.223 |     |       |                                                                                            |
|              | OAM Network               | seliics07837e09 | 10.196.120.224 |     |       |                                                                                            |
|              | OAM Network               | seliics07837e10 | 10.196.120.225 |     |       |                                                                                            |
|              | for additional uses       | seliics07837e03 | 10.196.127.183 |     |       |                                                                                            |

| Cluster name | Role                      |   Hostname      |   IP address   | CPU |  MEM  | HDD                                                                                        |
|--------------|---------------------------|-----------------|----------------|-----|-------|--------------------------------------------------------------------------------------------|
| seliics07839 | control-plane, worker     | seliics07839e01 | 10.196.120.204 | 40  | 314.9 | sda: 2,18TiB,sdb: 2,18TiB,sdc: 2,18TiB                                                     |
| VRID:51      | worker                    | seliics07839e02 | 10.196.120.205 | 40  | 314.9 | sda:2,18TiB,sdb:2,18TiB,sdc:2,18TiB                                                        |
|              | worker                    | seliics07840e01 | 10.196.120.207 | 40  | 314.9 | sda:2,18TiB,sdb:2,18TiB,sdc:2,18TiB                                                        |
|              | worker                    | seliics07840e02 | 10.196.120.208 | 40  | 314.9 | sda:2,18TiB,sdb:2,18TiB,sdc:2,18TiB                                                        |
|              | Traffic Ingestion Network | seliics07839e04 | 10.196.120.227 |     |       |                                                                                            |
|              | Traffic Ingestion Network | seliics07839e05 | 10.196.120.228 |     |       |                                                                                            |
|              | Traffic Ingestion Network | seliics07839e06 | 10.196.120.229 |     |       |                                                                                            |
|              | Analytics Data Network    | seliics07839e07 | 10.196.120.230 |     |       |                                                                                            |
|              | Reference Data Network    | seliics07839e08 | 10.196.121.78  |     |       |                                                                                            |
|              | OAM Network               | seliics07839e09 | 10.196.121.143 |     |       |                                                                                            |
|              | OAM Network               | seliics07839e10 | 10.196.121.144 |     |       |                                                                                            |
|              | for additional uses       | seliics07839e03 | 10.196.120.226 |     |       |                                                                                            |

| Cluster name | Role                      |   Hostname      |   IP address   | CPU |  MEM  | HDD                                                                                        |
|--------------|---------------------------|-----------------|----------------|-----|-------|--------------------------------------------------------------------------------------------|
| seliics07841 | control-plane, worker     | seliics07841e01 | 10.196.120.209 | 40  | 314.5 | sda: 2,18TiB,sdb: 2,18TiB,sdc: 2,18TiB                                                     |
| VRID:51      | worker                    | seliics07841e02 | 10.196.120.210 | 40  | 314.5 | sda:2,18TiB,sdb:2,18TiB,sdc:2,18TiB                                                        |
|              | worker                    | seliics07842e01 | 10.196.120.211 | 40  | 314.5 | sda:2,18TiB,sdb:2,18TiB,sdc:2,18TiB                                                        |
|              | worker                    | seliics07842e02 | 10.196.120.213 | 40  | 314.5 | sda:2,18TiB,sdb:2,18TiB,sdc:2,18TiB                                                        |
|              | Traffic Ingestion Network | seliics07841e04 | 10.196.121.146 |     |       |                                                                                            |
|              | Traffic Ingestion Network | seliics07841e05 | 10.196.121.148 |     |       |                                                                                            |
|              | Traffic Ingestion Network | seliics07841e06 | 10.196.121.149 |     |       |                                                                                            |
|              | Analytics Data Network    | seliics07841e07 | 10.196.121.150 |     |       |                                                                                            |
|              | Reference Data Network    | seliics07841e08 | 10.196.121.151 |     |       |                                                                                            |
|              | OAM Network               | seliics07841e09 | 10.196.121.153 |     |       |                                                                                            |
|              | OAM Network               | seliics07841e10 | 10.196.121.154 |     |       |                                                                                            |
|              | for additional uses       | seliics07841e03 | 10.196.121.145 |     |       |                                                                                            |

| Cluster name | Role                      |   Hostname      |   IP address   | CPU |  MEM  | HDD                                                                                        |
|--------------|---------------------------|-----------------|----------------|-----|-------|--------------------------------------------------------------------------------------------|
| seliics07843 | control-plane, worker     | seliics07843e01 | 10.196.120.215 | 40  | 314.5 | sda: 2,18TiB,sdb: 2,18TiB,sdc: 2,18TiB                                                     |
| VRID:51      | worker                    | seliics07843e02 | 10.196.121.80  | 40  | 314.5 | sda:2,18TiB,sdb:2,18TiB,sdc:2,18TiB                                                        |
|              | worker                    | seliics07844e01 | 10.196.121.81  | 40  | 314.5 | sda:2,18TiB,sdb:2,18TiB,sdc:2,18TiB                                                        |
|              | worker                    | seliics07844e02 | 10.196.121.82  | 40  | 314.5 | sda:2,18TiB,sdb:2,18TiB,sdc:2,18TiB                                                        |
|              | Traffic Ingestion Network | seliics07843e04 | 10.196.124.3   |     |       |                                                                                            |
|              | Traffic Ingestion Network | seliics07843e05 | 10.196.124.31  |     |       |                                                                                            |
|              | Traffic Ingestion Network | seliics07843e06 | 10.196.124.105 |     |       |                                                                                            |
|              | Analytics Data Network    | seliics07843e07 | 10.196.124.106 |     |       |                                                                                            |
|              | Reference Data Network    | seliics07843e08 | 10.196.124.107 |     |       |                                                                                            |
|              | OAM Network               | seliics07843e09 | 10.196.124.108 |     |       |                                                                                            |
|              | OAM Network               | seliics07843e10 | 10.196.124.109 |     |       |                                                                                            |
|              | for additional uses       | seliics07843e03 | 10.196.123.16  |     |       |                                                                                            |

| Cluster name | Role                      |   Hostname      |   IP address   | CPU |  MEM  | HDD                                                                                        |
|--------------|---------------------------|-----------------|----------------|-----|-------|--------------------------------------------------------------------------------------------|
| seliics07845 | control-plane, worker     | seliics07845e01 | 10.196.123.225 | 40  | 314.5 | sda: 2,18TiB,sdb: 2,18TiB,sdc: 2,18TiB                                                     |
| VRID:51      | worker                    | seliics07845e02 | 10.196.123.226 | 40  | 314.5 | sda:2,18TiB,sdb:2,18TiB,sdc:2,18TiB                                                        |
|              | worker                    | seliics07846e01 | 10.196.124.114 | 40  | 314.5 | sda:2,18TiB,sdb:2,18TiB,sdc:2,18TiB                                                        |
|              | worker                    | seliics07846e02 | 10.196.124.125 | 40  | 314.5 | sda:2,18TiB,sdb:2,18TiB,sdc:2,18TiB                                                        |
|              | Traffic Ingestion Network | seliics07845e04 | 10.196.124.36  |     |       |                                                                                            |
|              | Traffic Ingestion Network | seliics07845e05 | 10.196.124.32  |     |       |                                                                                            |
|              | Traffic Ingestion Network | seliics07845e06 | 10.196.124.33  |     |       |                                                                                            |
|              | Analytics Data Network    | seliics07845e07 | 10.196.124.110 |     |       |                                                                                            |
|              | Reference Data Network    | seliics07845e08 | 10.196.124.111 |     |       |                                                                                            |
|              | OAM Network               | seliics07845e09 | 10.196.124.112 |     |       |                                                                                            |
|              | OAM Network               | seliics07845e10 | 10.196.124.113 |     |       |                                                                                            |
|              | for additional uses       | seliics07845e03 | 10.196.124.35  |     |       |                                                                                            |

| Cluster name | Role                      |   Hostname      |   IP address   | CPU |  MEM  | HDD                                                                                        |
|--------------|---------------------------|-----------------|----------------|-----|-------|--------------------------------------------------------------------------------------------|
| seliics07847 | control-plane, worker     | seliics07847e01 | 10.196.124.158 | 40  | 314.5 | sda: 2,18TiB,sdb: 2,18TiB,sdc: 2,18TiB                                                     |
| VRID:51      | worker                    | seliics07847e02 | 10.196.124.159 | 40  | 314.5 | sda:2,18TiB,sdb:2,18TiB,sdc:2,18TiB                                                        |
|              | worker                    | seliics07848e01 | 10.196.124.184 | 40  | 314.5 | sda:2,18TiB,sdb:2,18TiB,sdc:2,18TiB                                                        |
|              | worker                    | seliics07848e02 | 10.196.124.185 | 40  | 314.5 | sda:2,18TiB,sdb:2,18TiB,sdc:2,18TiB                                                        |
|              | Traffic Ingestion Network | seliics07847e04 | 10.196.124.161 |     |       |                                                                                            |
|              | Traffic Ingestion Network | seliics07847e05 | 10.196.124.162 |     |       |                                                                                            |
|              | Traffic Ingestion Network | seliics07847e06 | 10.196.124.163 |     |       |                                                                                            |
|              | Analytics Data Network    | seliics07847e07 | 10.196.124.177 |     |       |                                                                                            |
|              | Reference Data Network    | seliics07847e08 | 10.196.124.181 |     |       |                                                                                            |
|              | OAM Network               | seliics07847e09 | 10.196.124.182 |     |       |                                                                                            |
|              | OAM Network               | seliics07847e10 | 10.196.124.183 |     |       |                                                                                            |
|              | for additional uses       | seliics07847e03 | 10.196.124.160 |     |       |                                                                                            |

| Cluster name | Role                      |   Hostname      |   IP address   | CPU |  MEM  | HDD                                                                                        |
|--------------|---------------------------|-----------------|----------------|-----|-------|--------------------------------------------------------------------------------------------|
| seliics07849 | control-plane, worker     | seliics07849e01 | 10.196.124.8   | 40  | 314.5 | sda: 2,18TiB,sdb: 2,18TiB,sdc: 2,18TiB                                                     |
| VRID:51      | worker                    | seliics04040e01 | 10.196.124.19  | 40  | 314.5 | sda:2,18TiB,sdb:2,18TiB,sdc:2,18TiB                                                        |
|              | worker                    | seliics04040e02 | 10.196.124.21  | 40  | 314.5 | sda:2,18TiB,sdb:2,18TiB,sdc:2,18TiB                                                        |
|              | worker                    | seliics07849e02 | 10.196.124.9   | 40  | 314.5 | sda:2,18TiB,sdb:2,18TiB,sdc:2,18TiB                                                        |
|              | Traffic Ingestion Network | seliics07849e04 | 10.196.124.12  |     |       |                                                                                            |
|              | Traffic Ingestion Network | seliics07849e05 | 10.196.124.13  |     |       |                                                                                            |
|              | Traffic Ingestion Network | seliics07849e06 | 10.196.124.190 |     |       |                                                                                            |
|              | Analytics Data Network    | seliics07849e07 | 10.196.124.14  |     |       |                                                                                            |
|              | Reference Data Network    | seliics07849e08 | 10.196.124.15  |     |       |                                                                                            |
|              | OAM Network               | seliics07849e09 | 10.196.124.17  |     |       |                                                                                            |
|              | OAM Network               | seliics07849e10 | 10.196.124.18  |     |       |                                                                                            |
|              | for additional uses       | seliics07849e03 | 10.196.124.11  |     |       |                                                                                            |

## EEA4 Tools Cluster

This cluster is for **Application Dashboard** and **AI4CI**.

| Cluster name | Role                      |   Hostname      |   IP address   | CPU |  MEM  | HDD                                                                                        |
|--------------|---------------------------|-----------------|----------------|-----|-------|--------------------------------------------------------------------------------------------|
| seliics03130 | control-plane, worker     | seliics03130e01 | 10.196.123.29  | 24  | 73.3  | sda: 1,09TiB,sdb: 7,28TiB                                                                  |
| VRID:51      | worker                    | seliics03130e02 | 10.196.123.30  | 22  | 68.4  | sda:7,28TiB,sdb:7,28TiB                                                                    |
|              | worker                    | seliics03130e03 | 10.196.123.49  | 22  | 68.4  | sda:7,28TiB,sdb:7,28TiB                                                                    |
|              |                           | seliics03130e05 | 10.196.123.52  |     |       |                                                                                            |
|              |                           | seliics03130e06 | 10.196.123.56  |     |       |                                                                                            |
|              |                           | seliics03130e04 | 10.196.123.51  |     |       |                                                                                            |

## EEA4 Application Dashboard Cluster

| Cluster name   | Role   | Hostname    | IP address    | CPU | MEM | HDD                   | vCloud host                                                                                                                                                                                |
|----------------|--------|-------------|---------------|-----|-----|-----------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| appdashboard   | master | selieea0026 | 10.223.227.29 | 6   | 8   | sda:200GiB            | [selieea0026.seli.gic.ericsson.se](https://vcloud.seli.gic.ericsson.se/tenant/ESTPDUOSSEEATE/vdcs/fc8e40aa-1be1-4cd1-9f5f-1667fdaf5df8/vm/vm-99f56f01-3300-4805-a887-d91afedb5e6d/general) |
| Master VRID: 3 | master | selieea0034 | 10.223.227.37 | 6   | 8   | sda:200GiB            | [selieea0034.seli.gic.ericsson.se](https://vcloud.seli.gic.ericsson.se/tenant/ESTPDUOSSEEATE/vdcs/fc8e40aa-1be1-4cd1-9f5f-1667fdaf5df8/vm/vm-57a0880b-c412-48dd-be34-0a90ab253013/general) |
|                | master | selieea0035 | 10.223.227.38 | 6   | 8   | sda:200GiB            | [selieea0035.seli.gic.ericsson.se](https://vcloud.seli.gic.ericsson.se/tenant/ESTPDUOSSEEATE/vdcs/fc8e40aa-1be1-4cd1-9f5f-1667fdaf5df8/vm/vm-2a4d54b2-b1c9-45a6-841d-4534c62bc106/general) |
| Worker VRID: 4 | worker | selieea0027 | 10.223.227.30 | 10  | 16  | sda:200GiB,sdb:100GiB | [selieea0027.seli.gic.ericsson.se](https://vcloud.seli.gic.ericsson.se/tenant/ESTPDUOSSEEATE/vdcs/fc8e40aa-1be1-4cd1-9f5f-1667fdaf5df8/vm/vm-d7b1a6e7-e836-44d9-b7ff-6f09c8180b79/general) |
|                | worker | selieea0028 | 10.223.227.31 | 10  | 16  | sda:200GiB,sdb:100GiB | [selieea0028.seli.gic.ericsson.se](https://vcloud.seli.gic.ericsson.se/tenant/ESTPDUOSSEEATE/vdcs/fc8e40aa-1be1-4cd1-9f5f-1667fdaf5df8/vm/vm-870d97e3-c93f-488c-9462-da8de68a438b/general) |
|                | worker | selieea0029 | 10.223.227.32 | 10  | 16  | sda:200GiB,sdb:100GiB | [selieea0029.seli.gic.ericsson.se](https://vcloud.seli.gic.ericsson.se/tenant/ESTPDUOSSEEATE/vdcs/fc8e40aa-1be1-4cd1-9f5f-1667fdaf5df8/vm/vm-58c64c28-76c0-4f39-917c-a289495b8e3f/general) |
|                | worker | selieea0030 | 10.223.227.33 | 10  | 16  | sda:200GiB,sdb:100GiB | [selieea0030.seli.gic.ericsson.se](https://vcloud.seli.gic.ericsson.se/tenant/ESTPDUOSSEEATE/vdcs/fc8e40aa-1be1-4cd1-9f5f-1667fdaf5df8/vm/vm-e4760e33-6d5f-4604-83ee-18284765be76/general) |

**Notes**:

* This cluster totally consist of VMs
* All necessary packages, utils, steps have been included in original images before the installation and saved snapshots for each VM
* Before reinstall the cluster it's required to manually stop all appropriate VMs and revert saved snapshots to clear everything from previous installation
* To reinstall one it's possible either to use [rv-ccd-install](https://seliius27190.seli.gic.ericsson.se:8443/job/rv-ccd-install/) Jenkins job (Parameters CLUSTER_NAME: cluster_productci_appdashboard, CCD_VERSION: 2.22.0, MAX_PODS: 200) or do it semiautomatically from EEA4 Admin node with Ansible playbooks using this [manual](https://gerrit.ericsson.se/plugins/gitiles/EEA/inv_test/+/master/eea4/install/CCD-installation.md)

## Jenkins build nodes

| Node                             | Host                                                                                                                                                             | Role                           | Description | Resources [Core/Ram/Disk(s)] |
|----------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------|--------------------------------|-------------|------------------------------|
| selieea0025.seli.gic.ericsson.se | [vCloud](https://vcloud.seli.gic.ericsson.se/tenant/ESTPDUOSSEEATE/vdcs/fc8e40aa-1be1-4cd1-9f5f-1667fdaf5df8/vm/vm-af4e67b9-3d9d-44e3-8d4f-251412ab3f23/general) | CI build server                | SLES 15 SP5 | 16c/64G/256G,128G            |
| selieea0031.seli.gic.ericsson.se | [vCloud](https://vcloud.seli.gic.ericsson.se/tenant/ESTPDUOSSEEATE/vdcs/fc8e40aa-1be1-4cd1-9f5f-1667fdaf5df8/vm/vm-be43644b-4815-43b9-a5df-71bda0164356/general) | CI build server                | SLES 15 SP5 | 16c/64G/256G,128G            |
| selieea0032.seli.gic.ericsson.se | [vCloud](https://vcloud.seli.gic.ericsson.se/tenant/estpduosseeate/vdcs/fc8e40aa-1be1-4cd1-9f5f-1667fdaf5df8/vm/vm-556c42c5-fac6-4d21-9102-87e757f9e886/general) | CI build server                | SLES 15 SP5 | 16c/64G/256G,128G            |
| selieea0037.seli.gic.ericsson.se | [vCloud](https://vcloud.seli.gic.ericsson.se/tenant/ESTPDUOSSEEATE/vdcs/fc8e40aa-1be1-4cd1-9f5f-1667fdaf5df8/vm/vm-15af0d60-bc6d-4a08-b6d2-74b88a6a27fc/general) | CI build server                | SLES 15 SP5 | 16c/32G/256G,128G            |
| selieea0069.seli.gic.ericsson.se | [vCloud](https://vcloud.seli.gic.ericsson.se/tenant/estpduosseeate/vdcs/fc8e40aa-1be1-4cd1-9f5f-1667fdaf5df8/vm/vm-69601649-c7ff-48b8-8a79-0c1199646378/general) | CI build server                | SLES 15 SP5 | 16c/64G/256G,128G            |
| selieea0045.seli.gic.ericsson.se | [vcloud](https://vcloud.seli.gic.ericsson.se/tenant/ESTPDUOSSEEATE/vdcs/fc8e40aa-1be1-4cd1-9f5f-1667fdaf5df8/vm/vm-aebf10ed-cbda-4af6-bb8d-ad0d4725c43c/general) | CI build server                | SLES 15 SP5 | 16c/64G/256G,128G            |
| selieea0046.seli.gic.ericsson.se | [vcloud](https://vcloud.seli.gic.ericsson.se/tenant/ESTPDUOSSEEATE/vdcs/fc8e40aa-1be1-4cd1-9f5f-1667fdaf5df8/vm/vm-c7e927e4-b9a7-47fd-9c4a-71f6ea0a81b3/general) | CI build server                | SLES 15 SP5 | 16c/64G/256G,128G            |
| selieea0093.seli.gic.ericsson.se | [vCloud](https://vcloud.seli.gic.ericsson.se/tenant/ESTPDUOSSEEATE/vdcs/fc8e40aa-1be1-4cd1-9f5f-1667fdaf5df8/vm/vm-1958858f-1589-43ac-a555-f71b04720f49) | CI build server                | SLES 15 SP5 | 16c/64G/256G,128G            |
| selieea0003.seli.gic.ericsson.se | [vCloud](https://vcloud.seli.gic.ericsson.se/tenant/ESTPDUOSSEEATE/vdcs/fc8e40aa-1be1-4cd1-9f5f-1667fdaf5df8/vm/vm-78fb21e6-ceaf-4dcb-a51a-b2115fc80702) | CI build server - Test Jenkins | SLES 15 SP5 | 16c/64G/300G,200G,2T         |

## EEA application dashboard verification jobs build nodes

| Node                              | Host                                                                                                                                                             | Role                      | Description | Resources [Core/Ram/Disk(s)] |
|-----------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------------------|-------------|------------------------------|
| selieea0074.seli.gic.ericsson.se  | [vCloud](https://vcloud.seli.gic.ericsson.se/tenant/ESTPDUOSSEEATE/vdcs/fc8e40aa-1be1-4cd1-9f5f-1667fdaf5df8/vm/vm-46b7adb6-1016-419b-97ef-d8bc67e136e6/general) | Maven projects build node | SLES 15 SP1 | 4c/16G/256G,500G             |
| seliics02417.seli.gic.ericsson.se | [iDRAC](https://seliics02417-sc.ete.ka.sw.ericsson.se/restgui/index.html?129a41088f3ca614adeaab9a172e68fa#/)                                                     | Maven projects build node | SLES 15 SP1 | 80c/256G/256G,560G           |

## Jenkins servers

| Node | Role | Description |
|------------ | ------------- | ------------- |
| seliius27102.seli.gic.ericsson.se | Test Jenkins server ||
| seliius27190.seli.gic.ericsson.se | Jenkins server ||

## ELK nodes

| Node | Role | Spec |
|------------ | ------------- | ------------- |
| [seliics00309.ete.ka.sw.ericsson.se](https://dl380x4226e01.seli.gic.ericsson.se/booking/server/3974) | Elasticsearch, Kibana | 64 cores; 256G mem; 6 TiB; |
| [seliics00310.ete.ka.sw.ericsson.se](https://dl380x4226e01.seli.gic.ericsson.se/booking/server/3983) | Elasticsearch, [Kibana](https://seliics00310.ete.ka.sw.ericsson.se:5601/)| 64 cores; 256G mem; 6 TiB; |
| [seliics00311.ete.ka.sw.ericsson.se](https://dl380x4226e01.seli.gic.ericsson.se/booking/server/3997) | Elasticsearch, Logstash, Kibana | 64 cores; 256G mem; 6 TiB; |

## NFS servers

| Node | Role | Description |
|------------ | ------------- | ------------- |
| [seliics00309.ete.ka.sw.ericsson.se](https://dl380x4226e01.seli.gic.ericsson.se/booking/server/3974) | NFS server ||

## EEA4 Admin node / Ansible server

| Node | Role | Description |
|------------ | ------------- | ------------- |
| seliics03093e01.seli.gic.ericsson.se | EEA4 Admin node | We ca execute from this server the EEA4 RV install steps |

## ADP dashboard visualization

|      Node      |            Role             |
|----------------|-----------------------------|
| 10.223.227.167 | ADP dashboard visualization |

## Test host

|                       Node           |             Host                  | Role                       |
|--------------------------------------|-----------------------------------|----------------------------|
| seliics03129e01.seli.gic.ericsson.se | [seliics03129](https://seliics03129.seli.gic.ericsson.se) | Test                       |
| seliics03129e02.seli.gic.ericsson.se | [seliics03129](https://seliics03129.seli.gic.ericsson.se) | CSAR based test activities |

access to [vCloud GUI](https://vcloud.seli.gic.ericsson.se/tenant/estpduosseeate/vdcs)
