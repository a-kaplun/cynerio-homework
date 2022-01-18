## Homework Instructions

1. Create a dockerfile to build the service. The dockerfile should be written
   using best practices.

   Details:
   Please find a `Dockerfile` inside of the `docker` folder
   1. I've used a MultiStage Docker build to exclude `poetry` on our Target Image
   2. Also, I am using the `alpine` based image due to it's small size and relatively small ammount of vulnerabilities
   3. I didn't added the healthcheck into the Dockerimage (instead we are using the one from the docker-compose file), although it can be done is needed

2. Create a docker-compose file to bring up the service together with Redis and Prometheus.
   Please find a `docker-compose.yaml` inside of the `docker` folder

   Details:
   - All environment variables are located inside of the `.env` file which is being automatically uploaded once we "start" the docker-compose

3. Redis should be configured to save the data **on every change** to an attached storage (in our case, a directory mounted into the container).

   Details:
   - To provide this functionality I've added 3 parameters into the `redis.conf` file (which is being mapped into the target container via the bind volumes):
   ```bash
      appendonly yes
      appendfsync everysec
      appendfilename "appendonly.aof"
   ```
      Some more information about it:
      - https://redis.io/topics/persistence
   - To provide the persistency we are also using the `volumes` directive inside of the `docker-compose.yaml` file which maps local `./redis/data` folder into the internal `/data` folder as described in the official documentation https://hub.docker.com/_/redis
   ```yaml
       volumes:
       - ./redis/data:/data
   ```

4. Redis should be configured with ACLs, user and password and
   **with the default password disabled**.

   Details
   - In this case I've created the `users.acl` file (which defines a `test` user account with access to any (only for our tests ;-))) and added it into our `redis.conf`, as below:
   ```bash
      aclfile /usr/local/etc/redis/users.acl
   ```
   - The next step was to map it into our redis container by using the `volumes` directive inside of the `docker-compose.yaml` file which maps local `./redis/acl/users.acl` file into the internal one, as below:
   ```yaml
      volumes:
      - ./redis/acl/users.acl:/usr/local/etc/redis/users.acl
   ```
   - Also, I've added an additional parameter into our redis startup command `--requirepass <REDIS_PASSWORD>` which will assign the password into our `default` user account and prevent any unathenticated actions inside of our cluster

5. Pass those credentials to the app service.

   Details:
   This was accomlished by passing an additional environment variable into our script `redis_password`
   ```python
      class Settings(BaseSettings):
         redis_url: str
         redis_password: str
   ```
   And changed the connection string to (we also needed to specify the `username` otherwise the connection failed):
   ```python
      @app.on_event("startup")
      def startup_event():
         global redis_con
         redis_con = redis.from_url(settings.redis_url,username="default",password=settings.redis_password)
   ```

6. The Prometheus service should be configured to get the metrics from the app.

   Details:
   - To support this behavior I've mapped the `prometheus.yml` file into the `prometheus` container with the new job and scrape config, as below:
   ```yaml
    - job_name: "api"
      static_configs:
       - targets: ["api:5000"]
      metrics_path: "/prom-metrics"
   ```
   - Also, I've created an additional `volume` map to provide persistency

7. All of the services should be configured with health checks.

   Details:
   - Each service was configure with the appropriate `healthcheck` directive
   - For all `HTTP` based services I've chosen to use the `wget --spider` scrape (`alpine` contains `wget` by default), this to prevent the need to install `curl`
   - For redis, I've used the `redis-cli`, again provide the password with the Environment Variable

8. Also, since the app does not have a health check currently, please write
   a healthcheck route under `/healthcheck` that will return `{"status": "ok"}`
   whenever it is called.

   Details:
   - Based on the existing code, I've added a new `/healthcheck` route which return `{'status': 'ok'}` then the connection to redis is working as expected
   ```python
   @app.get('/healthcheck', status_code=status.HTTP_200_OK)
   def perform_healthcheck(response: Response):
      r = redis.Redis.from_url(settings.redis_url,username="default",password=settings.redis_password, socket_connect_timeout=3)
      try:
         r.ping()
         response.status_code = status.HTTP_200_OK
      except:
         response.status_code = status.HTTP_404_NOT_FOUND
         return {'status': 'failure'}
      return {'status': 'ok'}
   ```

9. All of the services should be monitored by their aforementioned healthcheck
   by docker.

   Details:
   - All services are configured to be restarted `on-failure` (`restart: on-failure`)

## Execution Flow
1. Clone the repo
```bash
git clone https://github.com/a-kaplun/cynerio-homework.git
```
2. Inside of the cloned repo, change into the `docker` folder
```bash
cd docker
```

3. Create a `prometheus/data` folder for data with the appropriate permissions (otherwize the container will fail)
```bash
mkdir -p prometheus/data
sudo chgrp 65534 prometheus/data
```

4. Start the Docker Compose stack by using the command below:
```bash
docker-compose up -d
```

This will build the new `api` docker image and will start it with the `redis` and the `prometheus` containers
* All the container will run inside of the new `api-network` network
* both `api` and `prometheus` services will be exposed on host machine (5000 and 9090 correspondencly)
