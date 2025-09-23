# Instalacion de koha

Esta es una instalacion de koha basada en ip por lo que se necesitan puertos disponibles para agregarlos a la configuracion.

para correr el archivo ejecutar los siguientes comandos

```bash
chmod +x comandos.sh
sudo bash comandos.sh
```

para que se realice la instalacion de koha automaticamente ejecutar el archivo comandos.sh pero antes verificar en la funcion configurar_puertos se coloco el puerto 8080 para el intranet y el puerto 80 para el opac pero de no estar disponbles hay que cambiarlos.

Despues de ejecutar el archivo 


luego de la instalacion hay que modificar los archivos /etc/apache2/ports.conf para agregar el Listen para los puertos configurados en la funcion configurar_puertos.

```txt
Listen 80 <- cambiar el puerto por el puerto del opac si no esta disponible
Listen 8080 <- cambiar el puerto por el puerto del intranet si no esta disponible
```

luego de que la instalacion termine se debe modificar el archivo /etc/koha/sites/biblioteca/koha-conf.xml, se debe de buscar las lineas:

```xml
<enable_plugins>0</enable_plugins>
<plugins_restricted>1</plugins_restricted>
```

y cambiar los valores por lo siguiente

```xml
<enable_plugins>1</enable_plugins>
<plugins_restricted>0</plugins_restricted>
```

Tambien en la seccion plugin_repos descomentar la seccion para que se agregen los repos a la instalacion de koha.

Luego de la instalacion para acceder al instalador web de koha se puede obtener el usuario y contraseña de la base de datos de la instancia con el siguiente comando.

```bash
sudo koha-passwd biblioteca
```

En caso de que al acceder a la interfaz publica se muestre la pagina por defecto de apache se debe deshabilitar con el siguiente comando.

```bash
sudo a2dissite 000-default.conf
```
