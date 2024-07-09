FROM ubuntu
RUN ["apt","update"]
COPY test.txt /root
RUN ["apt","install","-y","screenfetch"]
ENTRYPOINT [ "/bin/bash" ]