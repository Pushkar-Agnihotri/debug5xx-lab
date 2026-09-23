# debug5xx lab

Small, runnable labs that reproduce production errors your logs never show.
Each folder is one bug, with a `run.sh bug` and a `run.sh fix`.

| Lab | Bug |
|---|---|
| [keepalive-502](keepalive-502/) | Random 502s when your app closes idle connections before the load balancer does |

Needs Docker and Python 3.
