// esto se ingresa en IntranetUserJS
document.addEventListener('DOMContentLoaded', function() {
    const logoImg = document.querySelector('#logo img');
    if (logoImg) {
        logoImg.src = '/intranet-tmpl/prog/img/escudo.png';
        logoImg.alt = 'Farusac';
    }
});