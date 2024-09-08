create or replace PACKAGE SessionHandler AS
    /*
    idSess esiste-> varchar con ruolo(Ruolo)
    IdSess non esiste-> null
    */
    function getRuolo( idSess IN varchar2) return varchar;

    /*
    idSess esiste-> int con ID dell'utente
    IdSess non esiste-> -1
    */
    function getIDuser( idSess IN varchar2) return int;

    /*
    ruolo corrisponde a IdSess-> true
    ruolo non corrisponde a idSess-> false
    */
    function checkRuolo( idSess IN varchar2, ruolo in varchar2) return boolean;

    /*
     idSess corretto-> restituisce il nome dell'utente associato alla sessione
     idSess non corretto-> null
     */
    function getUsername(idSess IN varchar2) return varchar2;

    /*
     la sessione esiste e non è terminata->true;
     la sessione non esiste o esiste ma è stata terminata->false
     */
    function checkSession(idSess IN Varchar2) return boolean;

     /*
     FUNZIONE INTERNA:
        dato il valore numerico di un ruolo, restiuisce il corrispondente valore testuale
     */
    function getStringRuolo(numberRuolo IN varchar2) return varchar2;

end SessionHandler;