use classroom;

var central = {
  "name": "central",
  "id": 38,
  "contact_email": "issues@mumuki.org",
  "description": "Aprendé a Programar",
  "book_id": 12,
  "profile": {
    "logo_url": "http://mumuki.io/logo-alt-large.png",
    "locale": "es",
    "description": "Aprendé a Programar",
    "contact_email": "issues@mumuki.org",
    "terms_of_service": null,
    "community_link": "https://www.facebook.com/groups/237784263357385/"
  },
  "theme": {
    "extension_javascript": "mumuki.load(function(){\r\n    $('.row:contains(10Pines SRL)').html('<div class=\"row text-center\">  <div>    <a href=\"https://www.10pines.com\" target=\"_blank\">      <img style=\"width: 15%\" src=\"https://www.10pines.com/assets/logo-big-e5a5b783b3e0a66c43cb5750770bf91fa0cee89e0703b83c90e3e1165580d886.png\">    </a>  </div>  <div>    Contenido creado por 10Pines bajo los términos de la <a href=\"https://creativecommons.org/licenses/by-sa/4.0/\" target=\"_blank\">Licencia Creative Commons Compartir-Igual, 4.0</a>.  </div>  <hr></div>')\r\n  })",
    "theme_stylesheet": ""
  },
  "settings": {
    "login_methods": [
      "facebook",
      "github",
      "google",
      "twitter",
      "user_pass"
    ],
    "raise_hand_enabled": false,
    "public": true,
    "immersive": false
  }
};

print('Creating central organization');
db.organizations.update({name: 'central'}, central, {upsert: true});


function updateStudent(uid, permissions) {
  print('Creating ' + uid + ' with permissions: ' + JSON.stringify(permissions));
  db.users.update(
    {uid: uid},
    {uid: uid, email: uid, first_name: 'Foo', last_name: 'Bar', name: 'Foo Bar', permissions: permissions},
    {upsert: true}
  );
}

updateStudent('dev.student@mumuki.org', {});
updateStudent('dev.teacher@mumuki.org', {teacher: '*/*'});
updateStudent('dev.owner@mumuki.org', {owner: '*/*'});
