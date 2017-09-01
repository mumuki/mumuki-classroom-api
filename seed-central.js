use classroom;

var central = {
  "name" : "central",
  "id" : 384,
  "contact_email" : "issues@mumuki.org",
  "description" : "¿Alguna vez te sucedió estar haciendo una tarea tediosa y repetitiva? ¿Te descubriste a vos mismo cometiendo errores por cansancio o distracción? ¿Te diste cuenta de que estabas perdiendo tiempo valioso en cosas que... podría hacer una máquina?\n\nTenemos una buena noticia para vos: ¡la programación puede ayudarte! Programar trata de usar nuestra creatividad e ingenio para resolver problemas y automatizar tareas con la ayuda de una computadora. \n\nY por si fuera poco, aprender a programar es fácil y entretenido. ¡Acompañanos!",
  "book_id" : 12,
  "created_at" : ISODate("2016-05-01T08:08:28.399Z"),
  "updated_at" : ISODate("2016-05-12T18:37:13.574Z"),
  "logo_url" : "http://mumuki.io/logo-alt-large.png",
  "private" : false,
  "locale" : "es",
  "lock_json" : {
    "dict" : "es",
    "connections" : [
      "facebook",
      "github",
      "google-oauth2",
      "twitter",
      "Username-Password-Authentication"
    ],
    "icon" : "/logo-alt.png",
    "socialBigButtons" : false,
    "disableResetAction" : false
  }
};

var fetchedCentral = db.organizations.findOne({name: 'central'});

if (!fetchedCentral) {
  print('Creating central organization');
  db.organizations.insert(central);
} else {
  print('Central organization is created');
}
