# Definir la imagen base
FROM ubuntu:20.04

# Actualizar la lista de paquetes e instalar los paquetes necesarios
RUN apt-get update -y && \
	apt-get upgrade -y 
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y apache2
 
RUN apt install -y systemctl 
RUN systemctl start apache2 
RUN apt install -y libapache2-mod-security2

COPY security2.conf /etc/apache2/mods-available

RUN mkdir /etc/modsecurity/activated_rules 
RUN mkdir /etc/modsecurity/base_rules 

COPY modsecurity.conf /etc/modsecurity

RUN apt install -y git 
RUN git clone https://github.com/SpiderLabs/owasp-modsecurity-crs /etc/modsecurity/owasp-modsecurity-crs
RUN mv /etc/modsecurity/owasp-modsecurity-crs /usr/share/modsecurity-crs 
RUN cp /usr/share/modsecurity-crs/owasp-modsecurity-crs/crs-setup.conf.example /usr/share/modsecurity-crs/owasp-modsecurity-crs/crs-setup.conf
	
COPY owasp-crs.load /usr/share/modsecurity-crs
	
RUN mkdir /var/log/modsecurity 
RUN service apache2 restart 

COPY apache2.conf /etc/apache2

RUN ln -s /usr/share/modsecurity-crs/rules/REQUEST-912-DOS-PROTECTION.conf /etc/modsecurity/activated_rules/ 
RUN apt install -y apache2-utils 
RUN a2enmod cache 
RUN a2enmod cache_disk 
RUN a2enmod expires 
RUN a2enmod headers 
RUN service apache2 restart 

COPY 000-default.conf /etc/apache2/sites-available

RUN service apache2 restart

COPY login.html /var/www/html
COPY styles.css /var/www/html

# Exponer el puerto 80 para que se pueda acceder al servidor web
EXPOSE 80

# Iniciar el servidor web al ejecutar el contenedor
CMD ["/usr/sbin/apache2ctl", "-D", "FOREGROUND"]
