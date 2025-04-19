
Elasticsearch Single with XPACK Enabled : https://gist.github.com/jinnabaalu/94ebaac4110ecd0e642b5fb05483ad35

Disable or Tune ILM / Watchers (Optional for Dev)
In non-prod setups, you can disable ILM or reduce default system watchers/alerts to free up resources.
environment:
      - xpack.ml.enabled=false
      - xpack.watcher.enabled=false
      - xpack.security.enabled=true  # keep if you want auth

Logstass
[JDBC POSTGRES DRIVERS](https://jdbc.postgresql.org/download/)