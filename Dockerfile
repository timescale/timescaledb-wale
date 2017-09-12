FROM python:2.7-stretch


RUN apt-get update && apt-get install curl lzop pv postgresql-client-9.6 cron -y \
     && rm -rf /var/lib/apt/lists/*

ADD https://bootstrap.pypa.io/get-pip.py .
RUN python get-pip.py

WORKDIR /usr/src/app
        
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY src/wale-rest.py .
COPY start.sh .
COPY backup_push.sh .

CMD [ "bash", "./start.sh" ]