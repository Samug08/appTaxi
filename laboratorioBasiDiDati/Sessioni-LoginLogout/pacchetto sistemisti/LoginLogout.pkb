create or replace PACKAGE BODY LOGINLOGOUT AS
    function aggiungiSessione(
                 cEmail IN varchar2,
                 psw IN varchar2,
                 ruolo IN VARCHAR2

    )
    return SESSIONIDIPENDENTI.IDSESSIONE%TYPE--=null se l'operazione fallisce
    IS
    idUtente int;
    idSess SESSIONIDIPENDENTI.IDSESSIONE%TYPE; --=null se l'operazione fallisce
    stateSession boolean;--true: indica se era già presente una sessione attiva prima di richiedere il login
    nullParameters exception;
    BEGIN
        idSess:=ruolo||to_char(SEQUENCEIDSESSIONIDIPENDENTI.nextval);
        case ruolo when '00' then
            --verifico che l'utente esista e sia attivo
                select c.IDcliente
                INTO idUtente
                from Clienti c
                where c.Email=cEmail and c.Password=psw and c.Stato=1;
            if(idUtente is null) then
                return null;
            end if;

            --credenziali non corrette
            --controllo se è già presente una sessione attiva per un utente
            stateSession:=LOGINLOGOUT.terminaSessioni(idUtente,ruolo);
            INSERT INTO SESSIONICLIENTI(idSessione,IDCLIENTE) values(idSess,idUtente);

        else
            case ruolo when '01' then--Operatori
                select d.MATRICOLA
                INTO idUtente
                from DIPENDENTI d JOIN OPERATORI o on o.FK_DIPENDENTE=d.MATRICOLA
                where d.EMAILAZIENDALE=cEmail and d.Password=psw and d.Stato=1;
            when '02' then--Operatori
                select d.MATRICOLA
                INTO idUtente
                from DIPENDENTI d JOIN AUTISTI A on A.FK_DIPENDENTE=d.MATRICOLA
                where d.EMAILAZIENDALE=cEmail and d.Password=psw and d.Stato=1;
            when '03' then--Manager
                select d.MATRICOLA
                INTO idUtente
                from DIPENDENTI d JOIN RESPONSABILI R on R.FK_DIPENDENTE=d.MATRICOLA
                where d.EMAILAZIENDALE=cEmail and d.Password=psw and d.Stato=1 AND r.RUOLO=0;
            when '04' then--Contabili
                select d.MATRICOLA
                INTO idUtente
                from DIPENDENTI d JOIN RESPONSABILI R on R.FK_DIPENDENTE=d.MATRICOLA
                where d.EMAILAZIENDALE=cEmail and d.Password=psw and d.Stato=1 AND r.RUOLO=1;
            end case;
            if(idUtente is null) then

                return null;
            end if;--credenziali non corrette
            stateSession:=LOGINLOGOUT.terminaSessioni(idUtente,ruolo);
            INSERT INTO SESSIONIDIPENDENTI(idSessione,IDDIPENDENTE) values(idSess,idUtente);
        end case;
        return idSess;
        EXCEPTION
			WHEN OTHERS THEN
                RETURN null;
    END aggiungiSessione;

    function terminaSessioni(idUser IN int, ruolo varchar2)
        return boolean
        IS
        BEGIN
            if Ruolo='00'then
                UPDATE SESSIONICLIENTI sc
                set sc.finesessione=SYSDATE
                where (sc.finesessione is NULL) and sc.IDCLIENTE=idUser;
                RETURN SQL%FOUND;
            else
                UPDATE SESSIONIDIPENDENTI sd
                set sd.finesessione=SYSDATE
                where (sd.finesessione is NULL) and sd.IDDIPENDENTE=idUser;
                RETURN SQL%FOUND;
            end if;
            EXCEPTION
                WHEN OTHERS THEN
                    RETURN FALSE;
        END terminaSessioni;
    function terminaSessione(idSess SESSIONIDIPENDENTI.IDSESSIONE%TYPE)
        return boolean
        IS
        BEGIN
            if SESSIONHANDLER.CHECKRUOLO(idSess,'Cliente')then
                UPDATE SESSIONICLIENTI sc
                set sc.finesessione=SYSDATE
                where sc.IDSESSIONE=idSess and sc.FINESESSIONE is null;
                RETURN SQL%FOUND;
            else
                UPDATE SESSIONIDIPENDENTI sd
                set sd.finesessione=SYSDATE
                where sd.IDSESSIONE=idSess and sd.FINESESSIONE is null;
                RETURN SQL%FOUND;
            end if;
             EXCEPTION
                WHEN OTHERS THEN
                    RETURN FALSE;
        END terminaSessione;
END LOGINLOGOUT;