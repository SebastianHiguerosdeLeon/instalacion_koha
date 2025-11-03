// esto se agrega en OpacUsersJS
$(document).ready(function(){
	$('#notloggedin').prepend('<div id="carrusel"><span id="coverflow">Cargando...</span></div>');
  	$('#loggedin').prepend('<div id="carrusel-logged"><span id="coverflow">Cargando...</span></div>');
  $('#searchform').prepend('<h2 id="titulo-farusac" style="text-align: center;color:white;font-family:sans-seriff">Biblioteca de la Facultad de Arquitectura USAC</h2>');
});

document.title = document.title.replace(" :: Koha", "");
document.title = document.title.replace("Koha :: ", "");
document.title = document.title.replace("Koha", "");