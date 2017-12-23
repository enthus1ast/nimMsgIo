Run 

  nim c genKeys.nims

or 

  exec openssl req -x509 -nodes -days 365 -newkey rsa:1024 -keyout mycert.pem -out mycert.pem


create SSL supporting transports with (see msgIoServer.nim for an example):
  enableSsl = true,
  sslKeyFile = "./ssl/mycert.pem",
  sslCertFile = "./ssl/mycert.pem"

build your server with "-d:ssl" compile time flag   


Compatible clients have to do the ssl handshake directly after connection