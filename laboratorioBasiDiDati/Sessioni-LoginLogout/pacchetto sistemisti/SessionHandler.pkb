create or replace PACKAGE BODY SessionHandler AS
   function getRuolo(idSess IN varchar2)
       RETURN varchar
       IS
    BEGIN
        return getStringRuolo(SUBSTR(idSess, 1, 2));
    END getRuolo;
   function getIDuser(idSess IN varchar2)
       RETURN int
       IS idUser int;

    begin
        idUser:=NULL;
        if getRuolo(idSess)='Cliente' then
            SELECT SESSIONICLIENTI.IDCLIENTE into idUser from SESSIONICLIENTI WHERE SESSIONICLIENTI.IDSESSIONE=idSess;
        else
            SELECT SESSIONIDIPENDENTI.IDDIPENDENTE into idUser from SESSIONIDIPENDENTI WHERE SESSIONIDIPENDENTI.IDSESSIONE=idSess;
        end if;
        return idUser;
        EXCEPTION
        WHEN NO_DATA_FOUND
            THEN
                RETURN null;

    end getIDuser;
   function checkRuolo( idSess IN varchar2, ruolo in varchar2) return boolean
    is
    begin
        return SESSIONHANDLER.GETRUOLO(idSess)=ruolo;
    end checkRuolo;
   function checkSession(idSess IN Varchar2) return boolean
   IS
       role varchar2(10);
       counter integer;
       BEGIN
            role:=getRuolo(idSess);
            if role is not null then
                if role='Cliente' then
                    SELECT count(*) into counter from SESSIONICLIENTI where SESSIONICLIENTI.IDSESSIONE=idSess and SESSIONICLIENTI.FINESESSIONE is null;
                    if counter>0 then return true; end if;
                else
                    SELECT count(*) into counter from SESSIONIDIPENDENTI where SESSIONIDIPENDENTI.IDSESSIONE=idSess and SESSIONIDIPENDENTI.FINESESSIONE is null;
                    if counter>0 then return true; end if;
                end if;
            end if;
            return false;
            htp.prn(sqlerrm);
            EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                    RETURN false;
       END checkSession;

   function getUsername(idSess IN varchar2) return varchar2
    is
        user varchar2(20);
    begin
        user:=null;
        case getRuolo(idSess)
            when 'Cliente' then
                select c.nome into user
                    FROM SESSIONICLIENTI sc JOIN CLIENTI c on sc.IDCLIENTE=c.IDCLIENTE
                    where sc.IDSESSIONE=idSess
                    FETCH FIRST 1 ROW ONLY;
            when 'Operatore' then
                select d.nome into user
                    FROM SESSIONIDIPENDENTI sc JOIN DIPENDENTI d on sc.IDDIPENDENTE=d.MATRICOLA
                        JOIN OPERATORI o on o.FK_DIPENDENTE=sc.IDDIPENDENTE
                        where sc.IDSESSIONE=idSess
                        FETCH FIRST 1 ROW ONLY;
            when 'Autista' then
                select d.nome into user
                    FROM SESSIONIDIPENDENTI sc JOIN DIPENDENTI d on sc.IDDIPENDENTE=d.MATRICOLA
                        JOIN AUTISTI a on a.FK_DIPENDENTE=sc.IDDIPENDENTE
                        where sc.IDSESSIONE=idSess
                        FETCH FIRST 1 ROW ONLY;
            when 'Manager' then
                select d.nome into user
                    FROM SESSIONIDIPENDENTI sc JOIN DIPENDENTI d on sc.IDDIPENDENTE=d.MATRICOLA
                        JOIN RESPONSABILI r on r.FK_DIPENDENTE=sc.IDDIPENDENTE
                    where r.RUOLO=0 and sc.IDSESSIONE=idSess
                    FETCH FIRST 1 ROW ONLY;
            when 'Contabile' then
                select d.nome into user
                    FROM SESSIONIDIPENDENTI sc JOIN DIPENDENTI d on sc.IDDIPENDENTE=d.MATRICOLA
                        JOIN RESPONSABILI r on r.FK_DIPENDENTE=sc.IDDIPENDENTE
                    where r.RUOLO=1 and sc.IDSESSIONE=idSess
                    FETCH FIRST 1 ROW ONLY;
        end case;
        return user;
        EXCEPTION
            WHEN OTHERS THEN
                RETURN NULL;
    end;
   function getStringRuolo(numberRuolo IN varchar2)
        return varchar2
    is
    begin
        CASE numberRuolo WHEN '00' then
            return 'Cliente';
        WHEN '01' THEN
            return 'Operatore';
        WHEN '02' THEN
            return 'Autista';
        WHEN '03' THEN
            return 'Manager';
        WHEN '04' THEN
            return 'Contabile';
        ELSE RETURN NULL;
        END CASE;
    end getStringRuolo;
end SessionHandler;