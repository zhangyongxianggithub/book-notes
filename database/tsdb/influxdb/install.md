# docker
```shell
docker run -d -p 8086:8086 \
  --name influxdb \
  -v $PWD/config.yml:/etc/influxdb2/config.yml \
  -v $PWD:/var/lib/influxdb2 \
  influxdb:2.6.1
```docker
```shell
# non-interacvtive方式,需要有-f --force
influx setup -u zyx -p zhang163766 -t zhang163766 -o zyx -b test -f
```
```shell
# Set up a configuration profile
influx config create -n default \
  -u http://localhost:8086 \
  -o INFLUX_ORG \
  -t INFLUX_API_TOKEN \
  -a
```
```shell
influx auth create \
  --all-access \
  --host http://localhost:8086 \
  --org <YOUR_INFLUXDB_ORG_NAME> \
  --token <YOUR_INFLUXDB_OPERATOR_TOKEN>
# 生成access token
# JNZFjuAF2SDwVDMuBf9sqDA4jBFzG4Ln-eR3oCC9alafsEovCxn2Y8SmJX2bz_vu2Q4-evQhr8aq7U5kvw5SbQ==
```
