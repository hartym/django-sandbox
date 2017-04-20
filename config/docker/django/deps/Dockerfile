FROM quay.io/okdocker/pynode:3.6-6.x

COPY ./requirements /app/requirements
COPY ./setup.py ./setup.cfg ./package.json ./yarn.lock  /app/

RUN groupadd -r django && useradd -r -g django -d /app django && chown -R django:django /app/
RUN pip install -r /app/requirements/production.txt
RUN sudo -u django yarn install
