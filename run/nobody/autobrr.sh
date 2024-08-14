#!/usr/bin/dumb-init /bin/bash


mkdir -p /config

#if [[ ! -f "/config/privoxy/config" ]]; then
#
    #echo "[info] Configuring Privoxy..."
    #cp -R /etc/privoxy/ /config/

    #sed -i -e "s~confdir /etc/privoxy~confdir /config/privoxy~g" /config/privoxy/config
    #sed -i -e "s~logdir /var/log/privoxy~logdir /config/privoxy~g" /config/privoxy/config
    #sed -i -e "s~listen-address.*~listen-address :8118~g" /config/privoxy/config

#fi

if [[ "${autobrr_running}" == "false" ]]; then

    echo "[info] Attempting to start autobrr..."

    # run autobrr (daemonized, non-blocking)
    timeout 10 yes | nohup /usr/sbin/autobrr --config /config >> '/config/autobrr.log' 2>&1 &

    # make sure process autobrr DOES exist
    retry_count=12
    retry_wait=1
    while true; do

        if ! pgrep -x "autobrr" > /dev/null; then

            retry_count=$((retry_count-1))
            if [ "${retry_count}" -eq "0" ]; then

                echo "[warn] Wait for autobrr process to start aborted, too many retries"
                echo "[info] Showing output from command before exit..."
                timeout 10 yes | /usr/sbin/autobrr --config /config >> '/config/autobrr.log' ; return 1

            else

                if [[ "${DEBUG}" == "true" ]]; then
                    echo "[debug] Waiting for autobrr process to start"
                    echo "[debug] Re-check in ${retry_wait} secs..."
                    echo "[debug] ${retry_count} retries left"
                fi
                sleep "${retry_wait}s"

            fi

        else

            echo "[info] autobrr process started"
            break

        fi

    done

    echo "[info] Waiting for autobrr process to start listening on port 7474..."

    while [[ $(netstat -lnt | awk "\$6 == \"LISTEN\" && \$4 ~ \".7474\"") == "" ]]; do
        sleep 0.1
    done

    echo "[info] autobrr process listening on port 7474"

fi

