<a href="https://www.postgresql.org" target="_blank">Postgres</a> is the World's Most Advanced Open Source Relational Database (according to them). <a href="https://www.pgadmin.org" target="_blank">PgAdmin</a> is the most popular and feature rich Open Source administration and development platform for PostgreSQL.

Follow this guide to integrate both in your Docker Swarm mode cluster deployed as described in <a href="https://dockerswarm.rocks" target="_blank">DockerSwarm.rocks</a> with a global Traefik HTTPS proxy.

Here's the pgadmin screen:

<img src="https://dockerswarm.rocks/img/pgadmin4.png">

## Preparation

* Connect via SSH to a Docker Swarm manager node.

* Create an environment variable with the domain where you want to access your PgAdmin instance, e.g.:

```bash
export DOMAIN=pgadmin.sys.example.com
```

* Make sure that your DNS records point that domain (e.g. `pgadmin.sys.example.com`) to one of the IPs of the Docker Swarm mode cluster.

* Get the Swarm node ID of this (manager) node and store it in an environment variable:

```bash
export NODE_ID=$(docker info -f '{{.Swarm.NodeID}}')
```

* Create a tag in this node, so that PgAdmin is always deployed to the same node and uses the existing volume:

```bash
docker node update --label-add pgadmin.pgadmin-data=true $NODE_ID
```

## Create the Docker Compose file

* Download the file `postgres.yml`:

```bash
curl -L dockerswarm.rocks/postgres.yml -o postgres.yml
```

* ...or create it manually, for example, using `nano`:

```bash
nano postgres.yml
```

* And copy the contents inside:

```YAML
{!./postgres.yml!}
```

!!! info
    This is just a standard Docker Compose file.
    
    It's common to name the file `docker-compose.yml` or something like `docker-compose.postgres.yml`.

    Here it's named just `postgres.yml` for brevity.


## Deploy it

Deploy the stack with:

```bash
docker stack deploy -c postgres.yml pgadmin
```

It will use the environment variables you created above.


## Check it

* Check if the stack was deployed with:

```bash
docker stack ps pgadmin
```

It will output something like:

```
ID             NAME                       IMAGE                        NODE              DESIRED STATE   CURRENT STATE          ERROR   PORT
xvyasdfh56hg   pgadmin_agent.b282rzs5   pgadmin/agent:latest       dog.example.com   Running         Running 1 minute ago
j3ahasdfe0mr   pgadmin_pgadmin.1      pgadmin/pgadmin:latest   cat.example.com   Running         Running 1 minute ago
```

* You can check the PgAdmin logs with:

```bash
docker service logs pgadmin_pgadmin
```


## Check the user interfaces

After some seconds/minutes, Traefik will acquire the HTTPS certificates for the web user interface.

You will be able to securely access the web UI at `https://<your pgadmin domain>` where you can create your username and password.

### Timing Note

    Make sure you login and create your credentials soon after PgAdmin is ready, or it will automatically shut down itself for security.

    If you didn't create the credentials on time and it shut down itself automatically, you can force it to restart with:

    ```bash
    docker service update pgadmin_pgadmin --force
    ```


## References

This guide on PgAdmin is adapted from the <a href="http://pgadmin.readthedocs.io/en/stable/agent.html" target="_blank">official PgAdmin documentation for Docker Swarm mode clusters</a>, adding deployment restrictions to make sure the same volume and database is always used and to enable HTTPS via Traefik, using the same ideas from <a href="https://dockerswarm.rocks" target="_blank">DockerSwarm.rocks</a>.
