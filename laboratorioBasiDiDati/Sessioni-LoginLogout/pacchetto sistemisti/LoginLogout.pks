create or replace PACKAGE LOGINLOGOUT AS
       function aggiungiSessione(
                 cEmail IN varchar2,
                 psw IN varchar2,
                 ruolo IN VARCHAR2
       )return SESSIONIDIPENDENTI.IDSESSIONE%TYPE;
       function terminaSessioni(
            idUser IN int,
            ruolo varchar2
       )return boolean;
       function terminaSessione(idSess SESSIONIDIPENDENTI.IDSESSIONE%TYPE)
        return boolean;

END LOGINLOGOUT;