/*PER LA CANCELLAZIONE DEI TRIGGER COMPILARE:
DROP TRIGGER trig1;
DROP TRIGGER trig10;
DROP TRIGGER trig11;
DROP TRIGGER trig12;
DROP TRIGGER trig13;
DROP TRIGGER trig14;
DROP TRIGGER trig15;
DROP TRIGGER trig16;
DROP TRIGGER trig17;
DROP TRIGGER trig18;
DROP TRIGGER trig19;
DROP TRIGGER trig2;
DROP TRIGGER trig20;
DROP TRIGGER trig21;
DROP TRIGGER trig22;
DROP TRIGGER trig23;
DROP TRIGGER trig24;
DROP TRIGGER trig25;
DROP TRIGGER trig26;
DROP TRIGGER trig27;
DROP TRIGGER trig28;
DROP TRIGGER trig29;
DROP TRIGGER trig3;
DROP TRIGGER trig30;
DROP TRIGGER trig31;
DROP TRIGGER trig32;
DROP TRIGGER trig33;
DROP TRIGGER trig34;
DROP TRIGGER trig35;
DROP TRIGGER trig36;
DROP TRIGGER trig37;
DROP TRIGGER trig38;
DROP TRIGGER trig39;
DROP TRIGGER trig4;
DROP TRIGGER trig40;
DROP TRIGGER trig41;
DROP TRIGGER trig42;
DROP TRIGGER trig43;
DROP TRIGGER trig44;
DROP TRIGGER trig45;
DROP TRIGGER trig46;
DROP TRIGGER trig47;
DROP TRIGGER trig48;
DROP TRIGGER trig5;
DROP TRIGGER trig53;
DROP TRIGGER trig6;
DROP TRIGGER trig60;
DROP TRIGGER trig7
DROP TRIGGER trig8;
DROP TRIGGER trig9;
*/
/*PER RENDERE LE TABELLE MODIFICABILI DAI TRIGGER COMPILARE:

ALTER TABLE RICHIESTEPRENLUSSO ENABLE ALL TRIGGERS;
ALTER TABLE POSSIEDETAXILUSSO ENABLE ALL TRIGGERS;
ALTER TABLE CORSEPRENOTATE ENABLE ALL TRIGGERS;
ALTER TABLE CORSENONPRENOTATE ENABLE ALL TRIGGERS;
ALTER TABLE PATENTI ENABLE ALL TRIGGERS;
ALTER TABLE AZIONIREVISIONE ENABLE ALL TRIGGERS;
ALTER TABLE REVISIONI ENABLE ALL TRIGGERS;
ALTER TABLE AZIONICORRETTIVE ENABLE ALL TRIGGERS;
ALTER TABLE TURNI ENABLE ALL TRIGGERS;
ALTER TABLE PRENOTAZIONELUSSO ENABLE ALL TRIGGERS;
ALTER TABLE PRENOTAZIONEACCESSIBILE ENABLE ALL TRIGGERS;
ALTER TABLE PRENOTAZIONESTANDARD ENABLE ALL TRIGGERS;
ALTER TABLE TAXILUSSO ENABLE ALL TRIGGERS;
ALTER TABLE TAXIACCESSIBILE ENABLE ALL TRIGGERS;
ALTER TABLE TAXISTANDARD ENABLE ALL TRIGGERS; 
ALTER TABLE TAXI ENABLE ALL TRIGGERS;
ALTER TABLE CONVENZIONIAPPLICATE ENABLE ALL TRIGGERS;
ALTER TABLE ANONIMETELEFONICHE ENABLE ALL TRIGGERS;
ALTER TABLE NONANONIME ENABLE ALL TRIGGERS;
ALTER TABLE CONVENZIONICLIENTI ENABLE ALL TRIGGERS;
ALTER TABLE OPERATORI ENABLE ALL TRIGGERS; 
ALTER TABLE AUTISTI ENABLE ALL TRIGGERS;
ALTER TABLE BUSTEPAGA ENABLE ALL TRIGGERS;
ALTER TABLE RESPONSABILI ENABLE ALL TRIGGERS;
ALTER TABLE RICARICHE ENABLE ALL TRIGGERS;
ALTER TABLE DIPENDENTI ENABLE ALL TRIGGERS;
ALTER TABLE OPTIONALS ENABLE ALL TRIGGERS;
ALTER TABLE PRENOTAZIONI ENABLE ALL TRIGGERS; 
ALTER TABLE CONVENZIONI ENABLE ALL TRIGGERS;
ALTER TABLE RUOLI ENABLE ALL TRIGGERS;
ALTER TABLE SESSIONI ENABLE ALL TRIGGERS;
ALTER TABLE SESSIONICLIENTI ENABLE ALL TRIGGERS;
ALTER TABLE SESSIONIDIPENDENTI ENABLE ALL TRIGGERS;

*/

/*PER RENDERE LE TABELLE IMMUNI AI TRIGGER:
ALTER TABLE RICHIESTEPRENLUSSO DISABLE ALL TRIGGERS;
ALTER TABLE POSSIEDETAXILUSSO DISABLE ALL TRIGGERS;
ALTER TABLE CORSEPRENOTATE DISABLE ALL TRIGGERS;
ALTER TABLE CORSENONPRENOTATE DISABLE ALL TRIGGERS;
ALTER TABLE PATENTI DISABLE ALL TRIGGERS;
ALTER TABLE AZIONIREVISIONE DISABLE ALL TRIGGERS;
ALTER TABLE REVISIONI DISABLE ALL TRIGGERS;
ALTER TABLE AZIONICORRETTIVE DISABLE ALL TRIGGERS;
ALTER TABLE TURNI DISABLE ALL TRIGGERS;
ALTER TABLE PRENOTAZIONELUSSO DISABLE ALL TRIGGERS;
ALTER TABLE PRENOTAZIONEACCESSIBILE DISABLE ALL TRIGGERS;
ALTER TABLE PRENOTAZIONESTANDARD DISABLE ALL TRIGGERS;
ALTER TABLE TAXILUSSO DISABLE ALL TRIGGERS;
ALTER TABLE TAXIACCESSIBILE DISABLE ALL TRIGGERS;
ALTER TABLE TAXISTANDARD DISABLE ALL TRIGGERS; 
ALTER TABLE TAXI DISABLE ALL TRIGGERS;
ALTER TABLE CONVENZIONIAPPLICATE DISABLE ALL TRIGGERS;
ALTER TABLE ANONIMETELEFONICHE DISABLE ALL TRIGGERS;
ALTER TABLE NONANONIME DISABLE ALL TRIGGERS;
ALTER TABLE CONVENZIONICLIENTI DISABLE ALL TRIGGERS;
ALTER TABLE OPERATORI DISABLE ALL TRIGGERS; 
ALTER TABLE AUTISTI DISABLE ALL TRIGGERS;
ALTER TABLE BUSTEPAGA DISABLE ALL TRIGGERS;
ALTER TABLE RESPONSABILI DISABLE ALL TRIGGERS;
ALTER TABLE RICARICHE DISABLE ALL TRIGGERS;
ALTER TABLE DIPENDENTI DISABLE ALL TRIGGERS;
ALTER TABLE OPTIONALS DISABLE ALL TRIGGERS;
ALTER TABLE PRENOTAZIONI DISABLE ALL TRIGGERS; 
ALTER TABLE CONVENZIONI DISABLE ALL TRIGGERS;
ALTER TABLE RUOLI DISABLE ALL TRIGGERS;
ALTER TABLE SESSIONI DISABLE ALL TRIGGERS;
ALTER TABLE SESSIONICLIENTI DISABLE ALL TRIGGERS;
ALTER TABLE SESSIONIDIPENDENTI DISABLE ALL TRIGGERS;
*/



--ANONIME TELEFONICHE

/*all’INSERIMENTO di una PRENOTAZIONE ANONIMA TELEFONICA:
lo stato della prenotazione associata può essere solo “accettata” oppure “rifiutata” (-20001)*/

CREATE OR REPLACE TRIGGER trig1
BEFORE INSERT on ANONIMETELEFONICHE
FOR EACH ROW
DECLARE
statoPrenotazioneAssociata VARCHAR(30);
except1 EXCEPTION;
BEGIN

    SELECT p.Stato INTO statoPrenotazioneAssociata
    FROM PRENOTAZIONI p
    WHERE p.IDprenotazione=:new.FK_Prenotazione;

    IF statoPrenotazioneAssociata!='accettata' AND statoPrenotazioneAssociata!='rifiutata' THEN

      RAISE except1;

    END IF;

  EXCEPTION WHEN except1 THEN RAISE_APPLICATION_ERROR(-20001, 'una prenotazione anonima telefonica può essere solo accettata o rifiutata.');

END;

/

--AUTISTI

/*All'INSERIMENTO di un AUTISTA:
 - si controlla che non siano presenti altre tuple nelle altre sottoclassi con riferimento allo stesso dipendente*/

CREATE OR REPLACE TRIGGER trig2 
BEFORE INSERT ON AUTISTI
FOR EACH ROW
DECLARE 
countRighe1 NUMBER;
countRighe2 NUMBER;

except2 EXCEPTION;

BEGIN

    countRighe1 := 0;
    countRighe2 := 0;

    SELECT COUNT(*)
    INTO countRighe1
    FROM RESPONSABILI r
    WHERE r.FK_DIPENDENTE = :new.FK_Dipendente;

    SELECT COUNT(*)
    INTO countRighe2
    FROM OPERATORI o
    WHERE o.FK_DIPENDENTE = :new.FK_Dipendente;

    IF (countRighe1 = 0 AND countRighe2 = 0) THEN
    
        INSERT INTO AUTISTI(FK_Dipendente, DataPatente) VALUES (:new.FK_Dipendente, :new.DataPatente);

    ELSE 
        
        RAISE except2;

    END IF;

    EXCEPTION
    WHEN except2 THEN RAISE_APPLICATION_ERROR(-20002, 'Il dipendente che si vuole inserire come autista è già inserito come dipendente per un altro ruolo.');
    
END;

/

/*al momento del cambiamento di stato in “inattivo” di un autista:
 - verranno cancellati con cascade i turni con data maggiore della data odierna a esso associati
 - se l’autista licenziato era referente di uno o più taxi si chiederà al manager di selezionare il nuovo referente dei taxi prima di cambiare lo stato.*/

CREATE OR REPLACE TRIGGER trig37
BEFORE UPDATE ON DIPENDENTI
FOR EACH ROW
WHEN (new.Stato = 0)
DECLARE 
esisteAutista NUMBER;
esisteReferente NUMBER;
except69 EXCEPTION;

BEGIN

    SELECT COUNT(*)
    INTO esisteAutista
    FROM AUTISTI a
    WHERE a.Fk_Dipendente = :old.Matricola;

    SELECT COUNT(*)
    INTO esisteReferente
    FROM TAXI t
    WHERE t.FK_Referente = :old.Matricola;

    IF(esisteAutista > 0)

        THEN DELETE FROM TURNI t
             WHERE t.FK_Autista = :new.Matricola AND SYSDATE < t.DataOraInizio;

    END IF;

    IF(esisteReferente > 0)

        THEN RAISE except69;

    END IF;

    EXCEPTION
    WHEN except69 THEN RAISE_APPLICATION_ERROR(-20069, 'Autista che si vuole disattivare è referente per alcuni taxi. sostituire referente prima di disattivare autista.');

END;

/

--AZIONI REVISIONE

/*In AzioniRevisione, non possono essere presenti FK_Revisione correlate a revisioni con l’attributo Risultato == “0”. 
Se esistono FK_Revisione con l’attributo Risultato == “1” allora dobbiamo controllare che la revisione precedente sia con risultato == “0” (-20003)*/

CREATE OR REPLACE TRIGGER trig3
BEFORE INSERT ON AZIONIREVISIONE
FOR EACH ROW
DECLARE
RisultatoRevisione NUMBER;
RisultatoRevisionePrecedente NUMBER;
DataRevisionePrecedente DATE;
TaxiRevisione NUMBER;
except3 EXCEPTION;

BEGIN

    SELECT Risultato
    INTO RisultatoRevisione
    FROM REVISIONI
    WHERE IDREVISIONE = :new.FK_Revisione;

    SELECT FK_TAXI
    INTO TaxiRevisione
    FROM REVISIONI
    WHERE IDREVISIONE = :new.FK_Revisione;

    IF (RisultatoRevisione = 0) THEN

        RAISE except3;

    END IF;

    SELECT MAX(DataOra)
    INTO DataRevisionePrecedente
    FROM REVISIONI
    WHERE FK_TAXI = TaxiRevisione AND :new.FK_REVISIONE != IDREVISIONE;

    SELECT Risultato
    INTO RisultatoRevisionePrecedente
    FROM REVISIONI
    WHERE FK_TAXI = TaxiRevisione AND DataOra = DataRevisionePrecedente;

    IF RisultatoRevisionePrecedente = 1 THEN

        RAISE except3;

    END IF;

    EXCEPTION
    WHEN except3 THEN RAISE_APPLICATION_ERROR(-20003, 'Non possono esserci azioni revisione per questa revisione.');
    
END;

/

--BUSTE PAGA

/*Nel momento dell’INSERIMENTO di una BUSTA PAGA di un dipendente:
 - la differenza tra la data di inserimento della busta paga precedente dello stesso dipendente e la data di inserimento corrente sia maggiore o uguale di un mese.*/


CREATE OR REPLACE TRIGGER trig4
BEFORE INSERT ON BUSTEPAGA
FOR EACH ROW
DECLARE
except4 EXCEPTION;

BEGIN

    FOR databustapaga IN (SELECT Data 
    FROM BUSTEPAGA b 
    WHERE b.FK_DIPENDENTE = :new.FK_DIPENDENTE)

    LOOP

        IF(TRUNC(databustapaga.Data, 'MM') = TRUNC(:new.Data, 'MM') AND TRUNC(databustapaga.Data, 'YYYY') = TRUNC(:new.Data, 'YYYY'))

            THEN RAISE except4;
        
        END IF;

    END LOOP;

    EXCEPTION 
    WHEN except4 THEN RAISE_APPLICATION_ERROR(-20004, 'Esiste già una busta paga nello stesso mese della busta paga che si vuole inserire.');

END;

/

--CLIENTI

/*Al momento del pagamento con il “portafoglio virtuale”:
il sistema controlla se l’importo è minore o uguale al saldo del cliente. [Nel caso in cui non fosse sufficiente, verrà notificato all’autista e il cliente dovrà pagare direttamente lui.] (-20005)*/

CREATE OR REPLACE TRIGGER trig5
BEFORE UPDATE ON CLIENTI
FOR EACH ROW
WHEN (new.Saldo < 0)
DECLARE
except5 EXCEPTION;

BEGIN

    RAISE except5;

    EXCEPTION
    WHEN except5 THEN RAISE_APPLICATION_ERROR(-20005, 'Il saldo del cliente non è sufficiente a coprire la spesa.');

END;

/

/*Quando lo stato di un cliente passa a “disattivato”:
 - ogni sua prenotazione, di cui non è stata fatta la corsa, verrà annullata.*/

CREATE OR REPLACE TRIGGER trig38  
AFTER UPDATE ON CLIENTI
FOR EACH ROW
WHEN (new.Stato = 0) /*Considerando "0" come lo stato "Inattivo"*/
BEGIN
    FOR item in( 

        SELECT *
        FROM NONANONIME n JOIN PRENOTAZIONI p  
        ON n.FK_Prenotazione = p.IDprenotazione
        WHERE SYSDATE < p.DataOra AND :new.IDcliente = n.FK_Cliente

    )
    LOOP

        UPDATE PRENOTAZIONI 
        SET PRENOTAZIONI.Stato = 'annullata' 
        WHERE(PRENOTAZIONI.IDprenotazione = item.IDprenotazione);

    END LOOP;
    
END;

/
--CONVENZIONI

/*Al momento della MODIFICA di una CONVENZIONE:
 -La data corrente deve essere minore della data di partenza della convenzione che si sta modificando (-20006)
 -La nuova data di inizio deve essere > della data odierna (-20007)*/

CREATE OR REPLACE TRIGGER trig6
BEFORE UPDATE ON CONVENZIONI
FOR EACH ROW
DECLARE
except6 EXCEPTION;
except7 EXCEPTION;

BEGIN

    IF (:old.DataInizio <= SYSDATE)

        THEN RAISE except6;
    
    END IF;

    IF(:new.DataInizio <= SYSDATE)

        THEN RAISE except7;
    
    END IF;

    EXCEPTION
    WHEN except6 THEN RAISE_APPLICATION_ERROR(-20006, 'La convenzione che si vuole modificare è già stata attivata.');
    WHEN except7 THEN RAISE_APPLICATION_ERROR(-20007, 'La nuova data che si vuole inserire nella convenzione è già passata.');

END;

/

/*al momento della MODIFICA DELL'INIZIO di una CONVENZIONE:
 - Se l’inizio è stato posticipato, si cancellano tutte le convenzioni applicate associate a quella convenzione presenti tra il vecchio inizio e il nuovo inizio.*/

CREATE OR REPLACE TRIGGER trig39
AFTER UPDATE ON CONVENZIONI
FOR EACH ROW
WHEN (old.DataInizio < new.DataInizio)

BEGIN

    FOR convenzioneapplicata IN (SELECT *
                                 FROM CONVENZIONIAPPLICATE ca JOIN PRENOTAZIONI p ON ca.FK_NONANONIME = p.IDPRENOTAZIONE
                                 WHERE FK_CONVENZIONE = :new.IDCONVENZIONE AND p.DataOra > :old.DataInizio AND p.DataOra < :new.DataInizio)

    LOOP

        DELETE FROM CONVENZIONIAPPLICATE
        WHERE FK_CONVENZIONE = convenzioneapplicata.FK_CONVENZIONE;

    END LOOP;

END;

/

--CONVENZIONI APPLICATE

/*Al momento della selezione di una convenzione da parte di un utente (inserimento di una convenzione applicata):
 - la data di scadenza deve essere maggiore o uguale della data per cui viene effettuata la prenotazione e la data d’inizio minore uguale della data per cui viene effettuata la prenotazione (-20008)
 - la data di inizio deve essere <= della data odierna (-20009)*/

CREATE OR REPLACE TRIGGER trig7
BEFORE INSERT ON CONVENZIONIAPPLICATE
FOR EACH ROW
DECLARE
DataOraPrenotazione DATE;
DataInizioConvenzione DATE;
DataFineConvenzione DATE;
except8 EXCEPTION;

BEGIN

    SELECT DataOra
    INTO DataOraPrenotazione
    FROM PRENOTAZIONI
    WHERE :new.FK_NONANONIME = IDPRENOTAZIONE;

    SELECT DataInizio
    INTO DataInizioConvenzione
    FROM CONVENZIONI
    WHERE :new.FK_CONVENZIONE = IDCONVENZIONE;

    SELECT DataFine
    INTO DataFineConvenzione
    FROM CONVENZIONI
    WHERE :new.FK_CONVENZIONE = IDCONVENZIONE;

    IF (DataOraPrenotazione > DataFineConvenzione OR DataOraPrenotazione < DataInizioConvenzione) THEN

        RAISE except8;

    END IF;

    EXCEPTION
    WHEN except8 THEN RAISE_APPLICATION_ERROR(-20008, 'La data della prenotazione non rientra nel periodo della convenzione.');
END;


/

--CORSE NON PRENOTATE

/*Nel momento dell’inserimento di una corsa non prenotata:
il numero di passeggeri deve essere <= del numero di posti disponibili del taxi associato (-20010)
essa non può avere orario di inizio maggiore rispetto all’orario di fine turno dell’autista associato. (-20011)
si controlla che l’orario di inizio della corsa sia >=oraInizioAltraCorsa+durata per ogni corsa associata a quel taxi in quel turno con orario di inizio <orarioInizioQuesta (-20012)*/

CREATE OR REPLACE TRIGGER trig8 
BEFORE INSERT ON CORSENONPRENOTATE
FOR EACH ROW

DECLARE
    npostitaxi NUMBER;
    orarioFineTurno DATE;
    autista NUMBER;
    oraFineAltraCorsa DATE;
    except10 EXCEPTION;
    except11 EXCEPTION;
    except12 EXCEPTION;
BEGIN
    SELECT t.Nposti into npostitaxi
    FROM TAXI t JOIN TAXISTANDARD ts on t.IDtaxi=ts.FK_Taxi
    WHERE :new.FK_Standard=ts.FK_Taxi;
    IF npostitaxi<:new.Passeggeri THEN
      RAISE except10;
    END IF;

    SELECT a.FK_dipendente into autista
    FROM AUTISTI a JOIN TURNI tu on tu.FK_Autista=a.FK_Dipendente JOIN TAXI ta ON tu.FK_Taxi=ta.IDtaxi JOIN TAXISTANDARD tas ON ta.IDtaxi=tas.FK_Taxi
    WHERE :new.FK_Standard=tas.FK_Taxi AND SYSDATE>=tu.DataOraInizioEff AND SYSDATE<=tu.DataOraFine;

    SELECT t.DataOraFine INTO orarioFineTurno
    FROM TURNI t
    WHERE t.FK_Autista = autista AND t.DataOraInizio<SYSDATE AND t.DataOraFine>SYSDATE;
    
    IF :new.DataOra > orarioFineTurno THEN
      RAISE except11;
    END IF;
    
    FOR altraCorsa IN (SELECT c.DataOra, c.durata
                       FROM CORSENONPRENOTATE c JOIN TAXI ta ON c.FK_STANDARD=ta.IDtaxi JOIN turni t ON t.FK_TAXI=ta.IDTAXI
                       WHERE :new.DataOra>=t.DATAORAINIZIO AND :new.DataOra<=t.DATAORAFINE
                       AND c.FK_Standard = :new.FK_Standard
                       AND c.DataOra < :new.DataOra
                       AND t.FK_Taxi=ta.IDtaxi AND t.DataOraInizio = (SELECT max(DataOraInizio) FROM TURNI WHERE DataOraInizio<:new.DataOra)
                      )
    LOOP
        oraFineAltraCorsa := altraCorsa.DataOra + NUMTODSINTERVAL(altraCorsa.Durata, 'MINUTE');
        IF :new.DataOra < oraFineAltraCorsa THEN
            RAISE except12;
        END IF;
    END LOOP;

    EXCEPTION 
      WHEN except10 THEN 
        RAISE_APPLICATION_ERROR(-20010, 'Numero di passeggeri maggiore del numero di posti del taxi');
      WHEN except11 THEN 
        RAISE_APPLICATION_ERROR(-20011, 'Orario della corsa oltre orario del turno di questo autista');
      WHEN except12 THEN 
        RAISE_APPLICATION_ERROR(-20012, 'L''orario di inizio della corsa non è valido rispetto alle altre corse associate a questo taxi.');
END;

/

/*al momento della MODIFICA di una CORSA NON PRENOTATA:
si controlla che siano trascorse meno di 24 ore dalla fine del turno in cui è stata effettuata, altrimenti si impedisce la modifica (-20015)*/

CREATE OR REPLACE TRIGGER trig10
BEFORE UPDATE on CORSENONPRENOTATE
FOR EACH ROW
DECLARE
oraFineTurno DATE;
except14 EXCEPTION;
BEGIN

    SELECT DataOraFine
    INTO oraFineTurno
    FROM TURNI
    WHERE FK_Taxi = :new.FK_Standard AND :new.DataOra > DataOraInizioEff AND :new.DataOra < DataOraFine;
    
    IF SYSDATE-oraFineTurno > 1 THEN
      RAISE except14;
    END IF;

    EXCEPTION 
      WHEN except14 THEN 
        RAISE_APPLICATION_ERROR(-20014, 'tempo per la modifica scaduto.');
END;

/

/*Nel momento dell’INSERIMENTO di una CORSA NON PRENOTATA:
se la corsa ha durata “null” (quindi non è ancora terminata) il taxi che la sta eseguendo deve passare allo stato “occupato”
 */

CREATE OR REPLACE TRIGGER trig40 
AFTER INSERT ON CORSENONPRENOTATE
FOR EACH ROW
BEGIN
    IF :new.Durata IS NULL THEN

        UPDATE TAXI
        SET stato = 'occupato'
        WHERE IDtaxi = :new.FK_Standard;

    END IF;
END;

/

/*al momento dell’INSERIMENTO della DURATA di una CORSA NON PRENOTATA:
 - si modifica lo stato del taxi associato in “disponibile”*/

CREATE OR REPLACE TRIGGER trig41
BEFORE UPDATE ON CORSENONPRENOTATE
FOR EACH ROW
WHEN (new.Durata IS NOT NULL)
DECLARE 

BEGIN

    UPDATE TAXI
    SET Stato = 'disponibile'
    WHERE :new.FK_Standard = TAXI.IDtaxi;

END;

/

--CORSE PRENOTATE

/*al momento dell’INSERIMENTO di una CORSA PRENOTATA
il numero di passeggeri deve essere <= del numero di posti disponibili del taxi associato (-20016)
FK_Prenotazione non deve riferire a una prenotazione con stato !=”accettata” (-20017)
la data di partenza deve essere = data odierna (-20018)
si controlla che l’orario di inizio della corsa sia >=oraInizioAltraCorsa+durata per ogni corsa associata a quel taxi in quel turno con orario di inizio <orarioInizioQuesta (-20019)*/

CREATE OR REPLACE TRIGGER trig11 
BEFORE INSERT ON CORSEPRENOTATE
FOR EACH ROW

DECLARE
    countStandard NUMBER;
    countLusso NUMBER;
    countAccessibile NUMBER;
    idtaxiAssegnato NUMBER;
    npostitaxi NUMBER;
    oraFineAltraCorsa DATE;
    statoPrenotazione VARCHAR2(30);
    except19 EXCEPTION;
    except18 EXCEPTION;
    except17 EXCEPTION;
    except16 EXCEPTION;
BEGIN
    countStandard := NULL;
    countLusso := NULL;
    countAccessibile := NULL;

    SELECT COUNT(*)
    INTO countStandard
    FROM PRENOTAZIONESTANDARD ps
    WHERE :new.FK_Prenotazione = ps.FK_Prenotazione;
    IF (countStandard > 0) THEN
        SELECT FK_Taxi
        INTO idtaxiAssegnato
        FROM PRENOTAZIONESTANDARD ps
        WHERE :new.FK_Prenotazione = ps.FK_Prenotazione;
    ELSE
      SELECT COUNT(*)
      INTO countLusso
      FROM PRENOTAZIONELUSSO pl
      WHERE :new.FK_Prenotazione = pl.FK_Prenotazione;    
      IF (countLusso > 0) THEN
          SELECT FK_Taxi
          INTO idtaxiAssegnato
          FROM PRENOTAZIONELUSSO pl
          WHERE :new.FK_Prenotazione = pl.FK_Prenotazione;
      ELSE
        SELECT COUNT(*)
        INTO countAccessibile
        FROM PRENOTAZIONEACCESSIBILE pa
        WHERE :new.FK_Prenotazione = pa.FK_Prenotazione;    
        IF (countAccessibile > 0) THEN
            SELECT FK_TaxiAccessibile
            INTO idtaxiAssegnato
            FROM PRENOTAZIONEACCESSIBILE pa
            WHERE :new.FK_Prenotazione = pa.FK_Prenotazione;
        END IF;
      END IF;
    END IF;

    SELECT t.Nposti INTO npostitaxi
    FROM TAXI t
    WHERE t.IDtaxi=idtaxiAssegnato;

    IF npostitaxi<:new.Passeggeri THEN
      RAISE except16;
    END IF;

    IF TRUNC(:new.DataOra) != TRUNC(SYSDATE) THEN
      RAISE except18;
    END IF;

    SELECT p.stato INTO statoPrenotazione
    FROM PRENOTAZIONI p
    WHERE p.IDprenotazione=:new.FK_Prenotazione;
    IF statoPrenotazione!='accettata'
    THEN RAISE except17;
    END IF;
    
    FOR altraCorsa IN (SELECT c.DataOra, c.durata
                       FROM CORSEPRENOTATE c JOIN PRENOTAZIONESTANDARD p on c.FK_Prenotazione=p.FK_Prenotazione JOIN TAXI ta ON p.FK_Taxi=ta.IDtaxi JOIN TURNI t ON ta.IDtaxi=t.FK_Taxi
                       WHERE ta.IDtaxi = idtaxiAssegnato
                       AND c.DataOra < :new.DataOra
                       AND t.DataOraInizio = (SELECT max(DataOraInizio) FROM TURNI WHERE DataOraInizio<:new.DataOra)
                      )
    LOOP
        oraFineAltraCorsa := altraCorsa.DataOra + NUMTODSINTERVAL(altraCorsa.Durata, 'MINUTE');
        IF :new.DataOra < oraFineAltraCorsa THEN
            RAISE except19;
        END IF;
    END LOOP;

    FOR altraCorsa IN (SELECT c.DataOra, c.durata
                       FROM CORSEPRENOTATE c JOIN PRENOTAZIONEACCESSIBILE p on c.FK_Prenotazione=p.FK_Prenotazione JOIN TAXI ta ON p.FK_TaxiAccessibile=ta.IDtaxi JOIN TURNI t ON ta.IDtaxi=t.FK_Taxi
                       WHERE ta.IDtaxi = idtaxiAssegnato
                       AND c.DataOra < :new.DataOra
                       AND t.DataOraInizio = (SELECT max(DataOraInizio) FROM TURNI WHERE DataOraInizio<:new.DataOra)
                      )
    LOOP
        oraFineAltraCorsa := altraCorsa.DataOra + NUMTODSINTERVAL(altraCorsa.Durata, 'MINUTE');
        IF :new.DataOra < oraFineAltraCorsa THEN
            RAISE except19;
        END IF;
    END LOOP;

    FOR altraCorsa IN (SELECT c.DataOra, c.durata
                       FROM CORSEPRENOTATE c JOIN PRENOTAZIONELUSSO p on c.FK_Prenotazione=p.FK_Prenotazione JOIN TAXI ta ON p.FK_Taxi=ta.IDtaxi JOIN TURNI t ON ta.IDtaxi=t.FK_Taxi
                       WHERE ta.IDtaxi = idtaxiAssegnato
                       AND c.DataOra < :new.DataOra
                       AND t.DataOraInizio = (SELECT max(DataOraInizio) FROM TURNI WHERE DataOraInizio<:new.DataOra)
                      )
    LOOP
        oraFineAltraCorsa := altraCorsa.DataOra + NUMTODSINTERVAL(altraCorsa.Durata, 'MINUTE');
        IF :new.DataOra < oraFineAltraCorsa THEN
            RAISE except19;
        END IF;
    END LOOP;

    EXCEPTION 
      WHEN except16 THEN 
        RAISE_APPLICATION_ERROR(-20016, 'Numero di passeggeri maggiore del numero di posti del taxi');
      WHEN except17 THEN
        RAISE_APPLICATION_ERROR(-20017, 'Prenotazione non accettata');
      WHEN except18 THEN 
        RAISE_APPLICATION_ERROR(-20018, 'La corsa deve essere inserita per la data odierna');
      WHEN except19 THEN 
        RAISE_APPLICATION_ERROR(-20019, 'L''orario di inizio della corsa non è valido rispetto alle altre corse associate a questo taxi.');
END;

/

/*al momento della MODIFICA di una CORSA PRENOTATA:
 - si controlla che siano trascorse meno di 24 ore dalla fine del turno in cui è stata effettuata, altrimenti si impedisce la modifica (-20022)*/

CREATE OR REPLACE TRIGGER trig12
BEFORE UPDATE on CORSEPRENOTATE
FOR EACH ROW
DECLARE
countStandard NUMBER;
countLusso NUMBER;
countAccessibile NUMBER;
idtaxiAssegnato NUMBER;
oraFineTurno DATE;
except22 EXCEPTION;
BEGIN
    --selezione taxi associato alla corsa

    countStandard := NULL;
    countLusso := NULL;
    countAccessibile := NULL;

    SELECT COUNT(*)
    INTO countStandard
    FROM PRENOTAZIONESTANDARD ps
    WHERE :new.FK_Prenotazione = ps.FK_Prenotazione;

    IF (countStandard > 0) THEN
        SELECT FK_Taxi
        INTO idtaxiAssegnato
        FROM PRENOTAZIONESTANDARD ps
        WHERE :new.FK_Prenotazione = ps.FK_Prenotazione;
    ELSE
      SELECT COUNT(*)
      INTO countLusso
      FROM PRENOTAZIONELUSSO pl
      WHERE :new.FK_Prenotazione = pl.FK_Prenotazione;    
      IF (countLusso > 0) THEN
          SELECT FK_Taxi
          INTO idtaxiAssegnato
          FROM PRENOTAZIONELUSSO pl
          WHERE :new.FK_Prenotazione = pl.FK_Prenotazione;
      ELSE
        SELECT COUNT(*)
        INTO countAccessibile
        FROM PRENOTAZIONEACCESSIBILE pa
        WHERE :new.FK_Prenotazione = pa.FK_Prenotazione;    
        IF (countAccessibile > 0) THEN
            SELECT FK_TaxiAccessibile
            INTO idtaxiAssegnato
            FROM PRENOTAZIONEACCESSIBILE pa
            WHERE :new.FK_Prenotazione = pa.FK_Prenotazione;
        END IF;
      END IF;
    END IF;

    --selezione turno in cui è avvenuta la corsa
    SELECT t.DATAORAFINEEFF
    INTO oraFineTurno
    FROM TURNI t
    WHERE t.FK_Taxi=idtaxiAssegnato AND t.DataOraInizio<=:new.DataOra AND t.DataOraFine>=:new.DataOra;
    
    --controllo orario
    IF SYSDATE - oraFineTurno > 1 THEN
      RAISE except22;
    END IF;

    EXCEPTION
      WHEN except22 THEN RAISE_APPLICATION_ERROR(-20022, 'tempo per la modifica scaduto.');
END;

/

/*al momento dell’INSERIMENTO di una CORSA PRENOTATA
se la corsa ha durata “null” (quindi non è ancora terminata) il taxi che la sta eseguendo deve passare allo stato “occupato”*/

CREATE OR REPLACE TRIGGER trig42 
AFTER INSERT ON CORSEPRENOTATE
FOR EACH ROW

DECLARE
    idtaxiAssegnato NUMBER;
    npostitaxi NUMBER;
    oraFineAltraCorsa DATE;
    statoPrenotazione VARCHAR2(9);
    countStandard NUMBER;
    countLusso NUMBER;
    countAccessibile NUMBER;
BEGIN

    countStandard := NULL;
    countLusso := NULL;
    countAccessibile := NULL;

    SELECT COUNT(*)
    INTO countStandard
    FROM PRENOTAZIONESTANDARD ps
    WHERE :new.FK_Prenotazione = ps.FK_Prenotazione;    

    IF (countStandard > 0) THEN

        SELECT FK_Taxi
        INTO idtaxiAssegnato
        FROM PRENOTAZIONESTANDARD ps
        WHERE :new.FK_Prenotazione = ps.FK_Prenotazione;
    
    END IF;

    SELECT COUNT(*)
    INTO countLusso
    FROM PRENOTAZIONELUSSO pl
    WHERE :new.FK_Prenotazione = pl.FK_Prenotazione;    

    IF (countLusso > 0) THEN

        SELECT FK_Taxi
        INTO idtaxiAssegnato
        FROM PRENOTAZIONELUSSO pl
        WHERE :new.FK_Prenotazione = pl.FK_Prenotazione;
    
    END IF;

    SELECT COUNT(*)
    INTO countAccessibile
    FROM PRENOTAZIONEACCESSIBILE pa
    WHERE :new.FK_Prenotazione = pa.FK_Prenotazione;    

    IF (countAccessibile > 0) THEN

        SELECT FK_TaxiAccessibile
        INTO idtaxiAssegnato
        FROM PRENOTAZIONEACCESSIBILE pa
        WHERE :new.FK_Prenotazione = pa.FK_Prenotazione;
    
    END IF;

    IF :new.Durata IS NULL THEN

        UPDATE TAXI
        SET stato = 'occupato'
        WHERE IDtaxi = idtaxiAssegnato;

    END IF;
    
END;

/

/* al momento dell’INSERIMENTO della DURATA di una CORSA PRENOTATA:
 - si modifica lo stato del taxi in “disponibile” */

CREATE OR REPLACE TRIGGER trig43
BEFORE UPDATE ON CORSEPRENOTATE
FOR EACH ROW
WHEN (new.Durata IS NOT NULL)
DECLARE 
IdTaxiCorsa NUMBER;
countPrenotazioni NUMBER;
categoriaPrenotazioneAssociata NUMBER; -- 0 -> PRENOTAZIONE STANDARD, 1 -> PRENOTAZIONE LUSSO, 2 -> PRENOTAZIONE ACCESSIBILE, 4 -> CORSA NON PRENOTATA

BEGIN

    --RICAVO A QUALE TIPO DI CATEGORIA APPARTIENE LA PRENOTAZIONE ASSOCIATA ALLA CORSA PRENOTATA DI CUI SI STA INSERENDO LA DURATA
    -- PRENOTAZIONI STANDARD
    SELECT COUNT(*)
    INTO countPrenotazioni
    FROM PRENOTAZIONESTANDARD ps
    WHERE ps.FK_Prenotazione = :new.FK_Prenotazione;

    IF (countPrenotazioni > 0)

        THEN categoriaPrenotazioneAssociata := 0;
             countPrenotazioni := 0;
    
    END IF; 

    -- PRENOTAZIONI LUSSO
    SELECT COUNT(*)
    INTO countPrenotazioni
    FROM PRENOTAZIONELUSSO pl
    WHERE pl.FK_Prenotazione = :new.FK_Prenotazione;

    IF (countPrenotazioni > 0)

        THEN categoriaPrenotazioneAssociata := 1;
             countPrenotazioni := 0;
    
    END IF; 

    -- PRENOTAZIONI ACCESSIBILE
    SELECT COUNT(*)
    INTO countPrenotazioni
    FROM PRENOTAZIONEACCESSIBILE pa
    WHERE pa.FK_Prenotazione = :new.FK_Prenotazione;

    IF (countPrenotazioni > 0)

        THEN categoriaPrenotazioneAssociata := 2;
             countPrenotazioni := 0;
    
    END IF;

    IF(categoriaPrenotazioneAssociata = 0) THEN

        --MI RICAVO L'ID DEL TAXI
        
        SELECT FK_Taxi
        INTO IdTaxiCorsa
        FROM PRENOTAZIONESTANDARD ps
        WHERE ps.FK_Prenotazione = :new.FK_Prenotazione;
 
    END IF; 

    IF(categoriaPrenotazioneAssociata = 1) THEN 

        --MI RICAVO L'ID DEL TAXI
        
        SELECT FK_Taxi
        INTO IdTaxiCorsa
        FROM PRENOTAZIONELUSSO pl
        WHERE pl.FK_Prenotazione = :new.FK_Prenotazione;

    END IF;

    IF(categoriaPrenotazioneAssociata = 2) THEN

        --MI RICAVO L'ID DEL TAXI

        SELECT FK_TaxiAccessibile
        INTO IdTaxiCorsa
        FROM PRENOTAZIONEACCESSIBILE pa
        WHERE pa.FK_Prenotazione = :new.FK_Prenotazione;


    END IF;

    UPDATE TAXI
    SET Stato = 'disponibile'
    WHERE IdTaxiCorsa = TAXI.IDtaxi;

END;

/

--NON ANONIME

/*Al momento dell’INSERIMENTO di un prenotazione NONANONIMA:
 - se la prenotazione è di tipo telefonico, l’operatore non può essere NULL.
 - se la prenotazione è di tipo “telefonica” può avere stato solo “accettata” o “rifiutata”*/


CREATE OR REPLACE TRIGGER trig13
BEFORE INSERT ON NONANONIME
FOR EACH ROW
DECLARE
except23 EXCEPTION;
except24 EXCEPTION;

BEGIN

    IF(:new.Tipo = 1 AND :new.FK_Operatore is NULL) THEN

        RAISE except23;    

    END IF;

    FOR prenotazione IN (SELECT *
                         FROM PRENOTAZIONI p
                         WHERE :new.FK_Prenotazione = p.IDprenotazione)
    LOOP
        
        IF(:new.Tipo = 1 AND (prenotazione.Stato = 'pendente' OR prenotazione.Stato = 'annullata'))

            THEN RAISE except24;

        END IF;
    
    END LOOP;

    EXCEPTION
    WHEN except23 THEN RAISE_APPLICATION_ERROR(-20023, 'L operatore della prenotazione Non Anonima telefonica che stiamo inserendo è NULLO.');
    WHEN except24 THEN RAISE_APPLICATION_ERROR(-20024, 'Lo stato della prenotazione Non Anonima telefonica che stiamo inserendo non è "rifiutata" o "accettata".');

END;

/

--OPERATORI

/*all'INSERIMENTO di un OPERATORE:
 - si controlla che non siano presenti altre tuple nelle altre sottoclassi con riferimento allo stesso dipendente*/

CREATE OR REPLACE TRIGGER trig14
BEFORE INSERT ON OPERATORI
FOR EACH ROW
DECLARE
countResponsabili NUMBER;
countAutisti NUMBER;
except25 EXCEPTION;
except26 EXCEPTION;

BEGIN

    SELECT COUNT(*)
    INTO countResponsabili
    FROM RESPONSABILI
    WHERE :new.FK_Dipendente = RESPONSABILI.FK_Dipendente;

    SELECT COUNT(*)
    INTO countAutisti
    FROM AUTISTI
    WHERE :new.FK_Dipendente = AUTISTI.FK_Dipendente;

    IF (countResponsabili > 0) THEN

        RAISE except25;
    
    END IF;

    IF (countAutisti > 0) THEN

        RAISE except26;

    END IF;

    EXCEPTION
    WHEN except25 THEN RAISE_APPLICATION_ERROR(-20025, 'IDoperatore che si vuole inserire è già presente come dipendente in Responsabili.');
    WHEN except26 THEN RAISE_APPLICATION_ERROR(-20026, 'IDoperatore che si vuole inserire è già presente come dipendente in Autisti.');

END;

/

--PRENOTAZIONI

/*al momento della MODIFICA della PRENOTAZIONE da parte dell’utente:
 -Si controlla se l’attributo modificata ha valore FALSE (in caso contrario si impedisce la modifica), in quel caso controlliamo che la differenza tra l’ora corrente e l’ora della prenotazione sia >=4 ore, altrimenti impediamo la modifica, e successivamente si cambia il valore dell’attributo modificata in “true”. (-20026)*/

CREATE OR REPLACE TRIGGER trig15
BEFORE UPDATE ON PRENOTAZIONI
FOR EACH ROW
WHEN (old.DataOra != new.DataOra)
DECLARE
except27 EXCEPTION;
except28 EXCEPTION;

BEGIN

    IF (:old.Modificata = 1)

        THEN RAISE except27;
    
    END IF;
    
    IF (:old.DataOra < SYSDATE + (1/6))

        THEN RAISE except28;
    
    END IF;

    :new.Modificata := 1;

    EXCEPTION
    WHEN except27 THEN RAISE_APPLICATION_ERROR(-20027, 'La data/ora della prenotazione è già stata modificata');
    WHEN except28 THEN RAISE_APPLICATION_ERROR(-20028, 'La prenotazione di cui si vuole modificare la data/ora è tra meno di 4 ore');

END;

/

/*al momento della MODIFICA della PRENOTAZIONE da parte dell’utente:
- si controlla che il numero di passeggeri (e numero di passeggeri con mobilità ridotta e optional richiesti per le prenotazioni che li prevedono) siano sempre compatibili con il taxi associato,
se non lo sono si lancia un'eccezione*/

CREATE OR REPLACE TRIGGER trig16
BEFORE UPDATE ON PRENOTAZIONI
FOR EACH ROW
WHEN (old.Npersone != new.Npersone)
DECLARE
taxiStandard NUMBER;
taxiLusso NUMBER;
taxiAccessibile NUMBER;
countStandard NUMBER;
countLusso NUMBER;
countAccessibile NUMBER;
numeroPostiTaxi NUMBER;
except29 EXCEPTION;

BEGIN

    countStandard := NULL;
    countLusso := NULL;
    countAccessibile := NULL;

    SELECT COUNT(*)
    INTO countStandard
    FROM PRENOTAZIONESTANDARD ps
    WHERE :new.IDPRENOTAZIONE = ps.FK_Prenotazione;    

    IF (countStandard > 0) THEN

        SELECT FK_Taxi
        INTO taxiStandard
        FROM PRENOTAZIONESTANDARD ps
        WHERE :new.IDPRENOTAZIONE = ps.FK_Prenotazione;

        SELECT NPOSTI
        INTO numeroPostiTaxi
        FROM TAXI t
        WHERE t.IDTAXI = taxiStandard;

        IF (numeroPostiTaxi < :new.Npersone) THEN

            RAISE except29;

        END IF;


    END IF;

    SELECT COUNT(*)
    INTO countLusso
    FROM PRENOTAZIONESTANDARD pl
    WHERE :new.IDPRENOTAZIONE = pl.FK_Prenotazione;

    IF (countLusso > 0) THEN

        SELECT FK_Taxi
        INTO taxiLusso
        FROM PRENOTAZIONELUSSO pl
        WHERE :new.IDPRENOTAZIONE = pl.FK_Prenotazione;

        SELECT NPOSTI
        INTO numeroPostiTaxi
        FROM TAXI t
        WHERE t.IDTAXI = taxiLusso;

        IF (numeroPostiTaxi < :new.Npersone) THEN

            RAISE except29;

        END IF;

        

    END IF;

    SELECT COUNT(*)
    INTO countAccessibile
    FROM PRENOTAZIONESTANDARD pa
    WHERE :new.IDPRENOTAZIONE = pa.FK_Prenotazione;

    IF (countAccessibile > 0) THEN

        SELECT FK_TAXIACCESSIBILE
        INTO taxiAccessibile
        FROM PRENOTAZIONEACCESSIBILE pa
        WHERE :new.IDPRENOTAZIONE = pa.FK_Prenotazione;

        SELECT NPOSTI
        INTO numeroPostiTaxi
        FROM TAXI t
        WHERE t.IDTAXI = taxiAccessibile;

        IF (numeroPostiTaxi < :new.Npersone) THEN

            RAISE except29;

        END IF;

    END IF;

    EXCEPTION
    WHEN except29 THEN RAISE_APPLICATION_ERROR(-20029, 'Il numero delle persone selezionato è maggiore del numero di posti del taxi associato.');
    WHEN NO_DATA_FOUND THEN 
    countStandard := 0;
    countLusso := 0;
    countAccessibile := 0;

END;

/

/*al momento della CANCELLAZIONE della PRENOTAZIONE:
si controlla che la differenza tra l’ora corrente e l’ora della prenotazione sia >=4 ore, altrimenti si impedisce la cancellazione. (-20030)*/

CREATE OR REPLACE TRIGGER trig17
BEFORE DELETE ON PRENOTAZIONI
FOR EACH ROW
DECLARE
except30 EXCEPTION;

BEGIN
    
    IF (:old.DataOra > SYSDATE - (1/6))

        THEN RAISE except30;
    
    END IF;

    DELETE FROM PRENOTAZIONI
    WHERE :old.IDprenotazione = PRENOTAZIONI.IDprenotazione;

    EXCEPTION
    WHEN except30 THEN RAISE_APPLICATION_ERROR(-20030, 'La prenotazione che si vuole eliminare è tra meno di 4 ore.');

END;

/

/*al momento dell’INSERIMENTO della PRENOTAZIONE:
- si controlla che, nel caso essa sia per il giorno corrente, sia in un orario successivo a quello corrente 
- si controlla che la data della prenotazione sia entro una settimana dalla data odierna (e >=della data odierna)*/

CREATE OR REPLACE TRIGGER trig18
BEFORE INSERT ON PRENOTAZIONI
FOR EACH ROW
DECLARE
except31 EXCEPTION;
except32 EXCEPTION;

BEGIN

    IF(:new.DataOra < SYSDATE) THEN

       RAISE except31;
    
    END IF;

    IF(:new.DataOra > SYSDATE + 7) THEN

        RAISE except32;

    END IF;

    EXCEPTION
    WHEN except31 THEN RAISE_APPLICATION_ERROR(-20031, 'La data/ora della prenotazione che si vuole inserire è minore della data/ora corrente.');
    WHEN except32 THEN RAISE_APPLICATION_ERROR(-20032, 'La data/ora della prenotazione che si vuole inserire è maggiore di una settimana rispetto alla data/ora corrente.');

END;

/

/*al momento dell’INSERIMENTO della PRENOTAZIONE NON ANONIMA:
- si controllano le convenzioni selezionate verificando che se c’è una convenzione non cumulabile non ce ne siano altre. */

CREATE OR REPLACE TRIGGER trig19
BEFORE INSERT ON CONVENZIONIAPPLICATE
FOR EACH ROW
DECLARE
except33 EXCEPTION;

BEGIN

    FOR convenzione IN (SELECT * 
                        FROM CONVENZIONIAPPLICATE ca JOIN CONVENZIONI c ON ca.FK_Convenzione = c.IDconvenzione
                        WHERE ca.FK_NonAnonime = :new.FK_NonAnonime)
    
    LOOP

        IF(convenzione.Cumulabile = 0)

            THEN RAISE except33;
        
        END IF;
    
    END LOOP;

    EXCEPTION
    WHEN except33 THEN RAISE_APPLICATION_ERROR(-20033, 'La prenotazione che si sta inserendo ha più di una convenzione non cumulabile.');

END;

/

/*al momento dell’INSERIMENTO della PRENOTAZIONE STANDARD:
- se la prenotazione ha stato “pendente” oppure “rifiutato” allora ha FK_Taxi==null*/

CREATE OR REPLACE TRIGGER trig20
BEFORE INSERT ON PRENOTAZIONESTANDARD
FOR EACH ROW
DECLARE
StatoPrenotazione VARCHAR2(10);
except34 EXCEPTION;

BEGIN

    SELECT Stato
    INTO StatoPrenotazione
    FROM PRENOTAZIONI 
    WHERE IDPRENOTAZIONE = :new.FK_Prenotazione;


    IF((StatoPrenotazione = 'rifiutata' OR StatoPrenotazione = 'pendente') AND :new.FK_Taxi IS NOT NULL)

            THEN RAISE except34;
        
    END IF;

    EXCEPTION
    WHEN except34 THEN RAISE_APPLICATION_ERROR(-20034, 'La prenotazione che si vuole inserire ha stato "pendente"/"rifiutata" pertanto deve avere FK_Taxi = NULL.');

END;

/

/*al momento dell’INSERIMENTO della PRENOTAZIONE LUSSO:
- se la prenotazione ha stato “pendente” oppure “rifiutato” allora ha FK_Taxi==null*/

CREATE OR REPLACE TRIGGER trig21
BEFORE INSERT ON PRENOTAZIONELUSSO
FOR EACH ROW
DECLARE
StatoPrenotazione VARCHAR2(10);
except34 EXCEPTION;

BEGIN

    SELECT Stato
    INTO StatoPrenotazione
    FROM PRENOTAZIONI p
    WHERE p.IDPRENOTAZIONE = :new.FK_Prenotazione;


    IF((StatoPrenotazione = 'rifiutata' OR StatoPrenotazione = 'pendente') AND :new.FK_Taxi IS NOT NULL)

            THEN RAISE except34;
        
    END IF;

    EXCEPTION
    WHEN except34 THEN RAISE_APPLICATION_ERROR(-20034, 'La prenotazione che si vuole inserire ha stato "pendente"/"rifiutata" pertanto deve avere FK_Taxi = NULL.');

END;

/

/*al momento dell’INSERIMENTO della PRENOTAZIONE ACCESSIBILE:
- se la prenotazione ha stato “pendente” oppure “rifiutato” allora ha FK_Taxi==null*/

CREATE OR REPLACE TRIGGER trig22
BEFORE INSERT ON PRENOTAZIONEACCESSIBILE
FOR EACH ROW
DECLARE
StatoPrenotazione VARCHAR2(10);
except34 EXCEPTION;

BEGIN

    SELECT Stato
    INTO StatoPrenotazione
    FROM PRENOTAZIONI p
    WHERE p.IDPRENOTAZIONE = :new.FK_Prenotazione;


    IF((StatoPrenotazione = 'rifiutata' OR StatoPrenotazione = 'pendente') AND :new.FK_TaxiAccessibile IS NOT NULL)

            THEN RAISE except34;
        
    END IF;

    EXCEPTION
    WHEN except34 THEN RAISE_APPLICATION_ERROR(-20034, 'La prenotazione che si vuole inserire ha stato "pendente"/"rifiutata" pertanto deve avere FK_Taxi = NULL.');
    
END;

/

/*al momento del cambiamento di stato di una prenotazione da “pendente” in “accettata”:
si controlla che la prenotazione abbia orario di partenza compreso negli orari previsti del turno (-20035)
si controlla che per ogni prenotazione già accettata vale che orarioInizioPrenotazioneGiàAccettata+durataPrevistaPrenotazioneGiàAccettata<orarioInizioPrenotazioneInAccettazione, e che le prenotazioni già accettate con orario successivo abbiano orarioInizioPrenotazioneInAccettazione+durataPrevistaPrenotazioneInAccettazione < orarioInizioPrenotazioneGiàAccettata (-20036)
si controlla che il numero di posti richiesti sia <= del numero di posti del taxi assegnato (-20037)
se la prenotazione è di tipo accessibile si controlla che il numero di posti richiesti sia <=numeroPostiDisabiliDelTaxiAssegnato (-20038)
si controlla che lo stato del taxi sia !=nonDisponibile (-20039)
se la prenotazione è di lusso si controlla che gli optionals associati alla prenotazione siano gli stessi associati al taxi assegnato (-20040)
si controlla che lo stato sia ancora “pendente” (per assicurarsi che la prenotazione non sia già stata accettata da un altro autista) (-20041)*/

CREATE OR REPLACE TRIGGER trig60
AFTER UPDATE on PRENOTAZIONI
FOR EACH ROW
WHEN (old.stato='pendente' AND new.stato='accettata')
DECLARE
    idtaxiAssegnato NUMBER;
    npostitaxi NUMBER;
    idPrenotazioneAccessibileCorrispondente NUMBER;
    idPrenotazioneLussoCorrispondente NUMBER;
    npostidisabili NUMBER;
    npersonedisabili NUMBER;
    statotaxiassegnato VARCHAR2(15);
    statoprenotazione VARCHAR2(9);
    autistaTurnoAssegnato NUMBER;
    orainizioTurnoAssegnato DATE;
    orafineturnoassegnato DATE;
    countStandard NUMBER;
    countLusso NUMBER;
    countAccessibile NUMBER;
    except41 EXCEPTION;
    except40 EXCEPTION;
    except39 EXCEPTION;
    except38 EXCEPTION;
    except37 EXCEPTION;
    except36A EXCEPTION;
    except36 EXCEPTION;
    except35 EXCEPTION;
    CURSOR c_optionals IS
      SELECT pt.FK_Optionals
      FROM POSSIEDETAXILUSSO pt
      WHERE pt.FK_TaxiLusso = idtaxiAssegnato;
    v_optional c_optionals%ROWTYPE;
--PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    --salvataggio id del taxi assegnato
    countStandard := NULL;
    countLusso := NULL;
    countAccessibile := NULL;

    SELECT COUNT(*)
    INTO countStandard
    FROM PRENOTAZIONESTANDARD ps
    WHERE :new.IDprenotazione = ps.FK_Prenotazione;    
    IF (countStandard > 0) THEN
        SELECT FK_Taxi
        INTO idtaxiAssegnato
        FROM PRENOTAZIONESTANDARD ps
        WHERE :new.IDprenotazione = ps.FK_Prenotazione;
    END IF;

    SELECT COUNT(*)
    INTO countLusso
    FROM PRENOTAZIONELUSSO pl
    WHERE :new.IDprenotazione = pl.FK_Prenotazione;    
    IF (countLusso > 0) THEN
        SELECT FK_Taxi
        INTO idtaxiAssegnato
        FROM PRENOTAZIONELUSSO pl
        WHERE :new.IDprenotazione = pl.FK_Prenotazione;
    END IF;

    SELECT COUNT(*)
    INTO countAccessibile
    FROM PRENOTAZIONEACCESSIBILE pa
    WHERE :new.IDprenotazione = pa.FK_Prenotazione;    
    IF (countAccessibile > 0) THEN
        SELECT FK_TaxiAccessibile
        INTO idtaxiAssegnato
        FROM PRENOTAZIONEACCESSIBILE pa
        WHERE :new.IDprenotazione = pa.FK_Prenotazione;
    END IF;

    --orario di partenza compreso negli orari del turno
    SELECT t.FK_Autista, t.DataOraInizio, t.DataOraFine INTO autistaTurnoAssegnato, orainizioTurnoAssegnato, orafineturnoassegnato
    FROM TURNI t
    WHERE t.FK_Taxi=idtaxiAssegnato AND t.DataOraInizio<=:new.DataOra AND t.DataOraFine>=:new.DataOra;

    IF autistaTurnoAssegnato IS NULL /*se la query fatta sopra non ha restituito risultato*/ THEN
      RAISE except35;       
    END IF;

    --si controlla che per ogni prenotazione già accettata vale che
    --orarioInizioPrenotazioneGiàAccettata+durataPrevistaPrenotazioneGiàAccettata<orarioInizioPrenotazioneInAccettazione
    --e che le prenotazioni già accettate con orario successivo abbiano
    --orarioInizioPrenotazioneInAccettazione+durataPrevistaPrenotazioneInAccettazione < orarioInizioPrenotazioneGiàAccettata
    --PRENOTAZIONI STANDARD
    FOR prenotaziones IN (SELECT *
                        FROM PRENOTAZIONESTANDARD ps JOIN PRENOTAZIONI p ON p.IDprenotazione = ps.FK_Prenotazione
                        WHERE idtaxiAssegnato = ps.FK_Taxi AND p.DataOra<=orafineturnoassegnato AND p.DataOra >=orainizioturnoassegnato)
    LOOP
      IF(:new.DataOra > prenotaziones.DataOra AND :new.DataOra < prenotaziones.DataOra + NUMTODSINTERVAL(prenotaziones.Durata, 'MINUTE'))
          THEN RAISE except36;
      END IF;

      IF(:new.DataOra < prenotaziones.DataOra AND :new.DataOra + (NUMTODSINTERVAL(:new.Durata, 'MINUTE')) > prenotaziones.DataOra)
          THEN RAISE except36A;
      END IF;
    END LOOP;

    --PRENOTAZIONI DI LUSSO
    FOR prenotazionel IN (SELECT *
                        FROM PRENOTAZIONELUSSO pl JOIN PRENOTAZIONI p ON p.IDprenotazione = pl.FK_Prenotazione
                        WHERE idtaxiAssegnato = pl.FK_Taxi AND p.DataOra<=orafineturnoassegnato AND p.DataOra >=orainizioturnoassegnato)
    LOOP
        IF(:new.DataOra > prenotazionel.DataOra AND :new.DataOra < prenotazionel.DataOra + NUMTODSINTERVAL(prenotazionel.Durata, 'MINUTE'))
            THEN RAISE except36;
        END IF;

        IF(:new.DataOra < prenotazionel.DataOra AND :new.DataOra + (NUMTODSINTERVAL(:new.Durata, 'MINUTE')) > prenotazionel.DataOra)
            THEN RAISE except36A;
        END IF;
    END LOOP;

    --PRENOTAZIONI ACCESSIBILI
    FOR prenotazionea IN (SELECT *
                        FROM PRENOTAZIONEACCESSIBILE pa JOIN PRENOTAZIONI p ON p.IDprenotazione = pa.FK_Prenotazione
                        WHERE idtaxiAssegnato = pa.FK_TaxiAccessibile AND p.DataOra<=orafineturnoassegnato AND p.DataOra >=orainizioturnoassegnato)
    LOOP
        IF(:new.DataOra > prenotazionea.DataOra AND :new.DataOra < prenotazionea.DataOra + NUMTODSINTERVAL(prenotazionea.Durata, 'MINUTE'))
            THEN RAISE except36;
        END IF;

        IF(:new.DataOra < prenotazionea.DataOra AND :new.DataOra + (NUMTODSINTERVAL(:new.Durata, 'MINUTE') /(24*60)) > prenotazionea.DataOra)
            THEN RAISE except36A;
        END IF;
    END LOOP;
    
    --numero di passeggeri <=numero posti taxi
    SELECT t.Nposti INTO npostitaxi
    FROM TAXI t
    WHERE t.IDtaxi=idtaxiAssegnato;

    IF npostitaxi<:new.Npersone THEN
      RAISE except37;
    END IF;

    --se la prenotazione è di tipo accessibile si controlla che il numero di posti richiesti sia <=numeroPostiDisabiliDelTaxiAssegnato
    IF countAccessibile>0 THEN
        SELECT p.FK_Prenotazione INTO idPrenotazioneAccessibileCorrispondente
        FROM PRENOTAZIONEACCESSIBILE p
        WHERE p.FK_Prenotazione=:new.IDprenotazione;
        IF idPrenotazioneAccessibileCorrispondente IS NOT NULL THEN
        SELECT p.NpersoneDisabili INTO npostidisabili
        FROM PRENOTAZIONEACCESSIBILE p
        WHERE p.FK_Prenotazione=:new.IDPrenotazione;
        SELECT t.NpersoneDisabili INTO npersonedisabili
        FROM TAXIACCESSIBILE t
        WHERE t.FK_Taxi=idtaxiAssegnato;
        IF npostidisabili<npersonedisabili THEN
            RAISE except38;
        END IF;
        END IF;
    END IF;

    --si controlla che lo stato del taxi sia !=nonDisponibile
    SELECT t.Stato INTO statotaxiassegnato
    FROM TAXI t
    WHERE t.IDtaxi=idtaxiAssegnato;
    IF statotaxiassegnato='non disponibile' THEN
      RAISE except39;
    END IF;

    --se la prenotazione è di lusso si controlla che gli optionals associati alla prenotazione siano gli stessi associati al taxi assegnato
    IF countLusso>0 THEN
        SELECT pl.FK_Prenotazione INTO idPrenotazioneLussoCorrispondente
        FROM PRENOTAZIONELUSSO pl
        WHERE pl.FK_Prenotazione=:new.IDprenotazione;
        IF idPrenotazioneLussoCorrispondente IS NOT NULL THEN
        FOR op IN (SELECT r.FK_Optionals FROM RICHIESTEPRENLUSSO r WHERE r.FK_PRENOTAZIONE=:new.IDPrenotazione) LOOP
            OPEN c_optionals;
            FETCH c_optionals INTO v_optional;
            CLOSE c_optionals;
            IF op.FK_Optionals != v_optional.FK_Optionals THEN
            RAISE except40;
            END IF;
        END LOOP;
        END IF;
    END IF;
    --si controlla che lo stato sia sempre “pendente” (per assicurarsi che la prenotazione non sia già stata accettata da un altro autista)
    SELECT p.Stato INTO statoprenotazione
    FROM PRENOTAZIONI p
    WHERE p.IDprenotazione=:new.IDprenotazione;
    IF statoprenotazione!='pendente' THEN
      RAISE except41;
    END IF;

    --si inserisce l’ID del taxi come chiave esterna del tipo di prenotazione corrispondente
      IF idPrenotazioneAccessibileCorrispondente IS NOT NULL THEN
        UPDATE PRENOTAZIONEACCESSIBILE pa
        SET pa.FK_TaxiAccessibile=idtaxiAssegnato
        WHERE pa.FK_Prenotazione=:new.IDprenotazione;

      ELSIF idPrenotazioneLussoCorrispondente IS NOT NULL THEN
        UPDATE PRENOTAZIONELUSSO pl
        SET pl.FK_Taxi=idtaxiAssegnato
        WHERE pl.FK_Prenotazione=:new.IDprenotazione;

      ELSE
        UPDATE PRENOTAZIONESTANDARD ps
        SET ps.FK_Taxi=idtaxiAssegnato
        WHERE ps.FK_Prenotazione=:new.IDprenotazione;
      END IF;

    EXCEPTION
      WHEN except35 THEN 
        RAISE_APPLICATION_ERROR(-20035, 'la prenotazione non è compresa negli orari del turno');
      WHEN except36 THEN
        RAISE_APPLICATION_ERROR(-20036, 'è presente altra corsa con orari sovrapposti');
      WHEN except36A THEN
        RAISE_APPLICATION_ERROR(-20036, 'è presente altra corsa con orari sovrapposti');
      WHEN except37 THEN
        RAISE_APPLICATION_ERROR(-20037, 'numero di passeggeri maggiore del numero di posti disponibili');
      WHEN except38 THEN
        RAISE_APPLICATION_ERROR(-20038, 'numero di passeggeri maggiore del numero di posti disponibili');
      WHEN except39 THEN
        RAISE_APPLICATION_ERROR(-20039, 'taxi assegnato non disponibile');
      WHEN except40 THEN
        RAISE_APPLICATION_ERROR(-20040, 'Optional richiesti non presenti nel taxi assegnato');
      WHEN except41 THEN
        RAISE_APPLICATION_ERROR(-20041, 'prenotazione non più pendente');
END;

/
/*al momento della MODIFICA dello STATO di una PRENOTAZIONE in "RIFIUTATA":
 - si controlla che il taxi associato sia NULL*/

CREATE OR REPLACE TRIGGER trig23
BEFORE UPDATE ON PRENOTAZIONI
FOR EACH ROW
WHEN (new.Stato = 'rifiutata')
DECLARE
idTaxi NUMBER;
countStandard NUMBER;
countLusso NUMBER;
countAccessibile NUMBER;
except42 EXCEPTION;

BEGIN

    SELECT COUNT(*)
    INTO countStandard
    FROM PRENOTAZIONESTANDARD ps
    WHERE ps.FK_PRENOTAZIONE = :new.IDPRENOTAZIONE;

    IF (countStandard > 0) THEN

        SELECT FK_Taxi
        INTO idTaxi
        FROM PRENOTAZIONESTANDARD ps
        WHERE ps.FK_PRENOTAZIONE = :new.IDPRENOTAZIONE;

        IF (idTaxi IS NOT NULL) THEN

            RAISE except42;

        END IF; 

    END IF;

    SELECT COUNT(*)
    INTO countLusso
    FROM PRENOTAZIONELUSSO pl
    WHERE pl.FK_PRENOTAZIONE = :new.IDPRENOTAZIONE;

    IF (countLusso > 0) THEN

        SELECT FK_Taxi
        INTO idTaxi
        FROM PRENOTAZIONELUSSO pl
        WHERE pl.FK_PRENOTAZIONE = :new.IDPRENOTAZIONE;

        IF (idTaxi IS NOT NULL) THEN

            RAISE except42;

        END IF;

    END IF;

    SELECT COUNT(*)
    INTO countAccessibile
    FROM PRENOTAZIONEACCESSIBILE pa
    WHERE pa.FK_PRENOTAZIONE = :new.IDPRENOTAZIONE;

    IF (countAccessibile > 0) THEN

        SELECT pa.FK_TAXIACCESSIBILE
        INTO idTaxi
        FROM PRENOTAZIONEACCESSIBILE pa
        WHERE pa.FK_PRENOTAZIONE = :new.IDPRENOTAZIONE;

        IF (idTaxi IS NOT NULL) THEN

            RAISE except42;

        END IF;

    END IF;

    EXCEPTION
    WHEN except42 THEN RAISE_APPLICATION_ERROR(-20042, 'La prenotazione di cui si vuole modificare lo stato in "rifiutata" deve avere il taxi associato NULL.');

END;

/

--PRENOTAZIONE ACCESSIBILE
/*Al momento dell’INSERIMENTO di una PRENOTAZIONE ACCESSIBILE:
 - si controlla che il taxi associato sia un taxi standard.*/

CREATE OR REPLACE TRIGGER trig24
BEFORE INSERT ON PRENOTAZIONEACCESSIBILE
FOR EACH ROW
WHEN (new.FK_TAXIACCESSIBILE IS NOT NULL)
DECLARE countRighe INTEGER (10);
except45 EXCEPTION;

BEGIN

    SELECT COUNT(*)                        
    INTO countRighe
    FROM TAXIACCESSIBILE t
    WHERE t.FK_TAXI = :new.FK_TAXIACCESSIBILE;

    IF (countRighe = 0)

        THEN RAISE except45;

   /* ELSE RAISE Tipologia_taxi;*/

    END IF;

    EXCEPTION
    WHEN except45 THEN RAISE_APPLICATION_ERROR(-20045, 'La categoria del taxi è diversa dalla categoria della prenotazione che si vuole inserire.');

END;

/

/*Al momento dell’INSERIMENTO di una PRENOTAZIONE STANDARD:
 - si controlla che il taxi associato sia un taxi standard.*/

CREATE OR REPLACE TRIGGER trig25
BEFORE INSERT ON PRENOTAZIONESTANDARD
FOR EACH ROW
WHEN (new.FK_TAXI IS NOT NULL)
DECLARE countRighe INTEGER (10);
except46 EXCEPTION;

BEGIN
                                
    SELECT COUNT(*)                        
    INTO countRighe
    FROM TAXISTANDARD t
    WHERE t.FK_TAXI = :new.FK_TAXI;

    IF (countRighe = 0)

        THEN RAISE except46;

    END IF;

    EXCEPTION
    WHEN except46 THEN RAISE_APPLICATION_ERROR(-20045, 'La categoria del taxi è diversa dalla categoria della prenotazione che si vuole inserire.');

END;

/

/*Al momento dell’INSERIMENTO di una PRENOTAZIONE di LUSSO:
 - si controlla che il taxi associato sia un taxi di lusso.*/

CREATE OR REPLACE TRIGGER trig26
BEFORE INSERT ON PRENOTAZIONELUSSO
FOR EACH ROW
WHEN (new.FK_TAXI IS NOT NULL)
DECLARE countRighe INTEGER (10);
except47 EXCEPTION;

BEGIN

    SELECT COUNT(*)                        
    INTO countRighe
    FROM TAXILUSSO t
    WHERE t.FK_TAXI = :new.FK_TAXI;

    IF (countRighe = 0)

        THEN RAISE except47;

    END IF;

    EXCEPTION
    WHEN except47 THEN RAISE_APPLICATION_ERROR(-20045, 'La categoria del taxi è diversa dalla categoria della prenotazione che si vuole inserire.');

END;

/


/*al momento del CAMBIAMENTO di STATO di una PRENOTAZIONE da "ACCETTATA" in "PENDENTE":
 - si fa diventare null FK_Taxi associato alla prenotazione*/

CREATE OR REPLACE TRIGGER trig45
AFTER UPDATE ON PRENOTAZIONI
FOR EACH ROW
WHEN (old.Stato = 'accettata' AND new.Stato = 'pendente')
DECLARE
countStandard NUMBER;
countLusso NUMBER;
countAccessibile NUMBER;

BEGIN

    SELECT COUNT(*)
    INTO countStandard
    FROM PRENOTAZIONESTANDARD ps
    WHERE ps.FK_Prenotazione = :new.IDPRENOTAZIONE;

    IF (countStandard > 0) THEN

        UPDATE PRENOTAZIONESTANDARD ps
        SET ps.FK_Taxi = NULL
        WHERE ps.FK_Prenotazione = :new.IDprenotazione;

    END IF;

    
    SELECT COUNT(*)
    INTO countLusso
    FROM PRENOTAZIONELUSSO pl
    WHERE pl.FK_Prenotazione = :new.IDPRENOTAZIONE;

    IF (countLusso > 0) THEN

        UPDATE PRENOTAZIONELUSSO pl
        SET pl.FK_Taxi = NULL
        WHERE pl.FK_Prenotazione = :new.IDprenotazione;

    END IF;

    SELECT COUNT(*)
    INTO countAccessibile
    FROM PRENOTAZIONEACCESSIBILE pa
    WHERE pa.FK_Prenotazione = :new.IDPRENOTAZIONE;

    IF (countAccessibile > 0) THEN

        UPDATE PRENOTAZIONEACCESSIBILE pa
        SET pa.FK_TaxiAccessibile = NULL
        WHERE pa.FK_Prenotazione = :new.IDprenotazione;

    END IF;


END;

/

/*dopo la modifica di una prenotazione da parte di un utente:
se o se viene cambiato uno qualunque degli altri attributi (data, ora, luogo di partenza, luogo di arrivo) lo stato della prenotazione diventa “pendente”*/
CREATE OR REPLACE TRIGGER trig48
BEFORE UPDATE ON PRENOTAZIONI
FOR EACH ROW
WHEN (old.LuogoPartenza != new.LuogoPartenza OR old.LuogoArrivo != new.LuogoArrivo)

BEGIN

    :new.Stato := 'pendente';

END;

/


--RESPONSABILI

/* all’INSERIMENTO di un RESPONSABILE:
 - si controlla che non siano presenti altre tuple nelle altre sottoclassi con riferimento allo stesso dipendente
 */

CREATE OR REPLACE TRIGGER trig27
BEFORE INSERT ON RESPONSABILI
FOR EACH ROW
DECLARE
countAutisti NUMBER;
countOperatori NUMBER;
except48 EXCEPTION;
except49 EXCEPTION;

BEGIN

    SELECT COUNT(*)
    INTO countAutisti
    FROM AUTISTI
    WHERE AUTISTI.FK_Dipendente = :new.FK_Dipendente;

    IF (countAutisti > 0)

        THEN RAISE except48;

    END IF;

    SELECT COUNT(*)
    INTO countOperatori
    FROM OPERATORI
    WHERE OPERATORI.FK_Dipendente = :new.FK_Dipendente;

    IF (countOperatori > 0)

        THEN RAISE except49;

    END IF;

    EXCEPTION
    WHEN except48 THEN RAISE_APPLICATION_ERROR(-20048, 'Il responsabile che si vuole inserire è già presente in Autisti.');
    WHEN except49 THEN RAISE_APPLICATION_ERROR(-20049, 'Il responsabile che si vuole inserire è già presente in Operatori.');

END;

/

--REVISIONI

/*alla MODIFICA del RISULTATO di una REVISIONE da qualsiasi valore (“1”/”0”) a “0”
la data di scadenza deve avere valore “NULL”.*/


CREATE OR REPLACE TRIGGER trig28
BEFORE UPDATE ON REVISIONI
FOR EACH ROW
WHEN(new.Risultato = 0)
DECLARE
except50 EXCEPTION;

BEGIN

    IF (:new.Scadenza IS NOT NULL)

        THEN RAISE except50;
    
    END IF;

    EXCEPTION
    WHEN except50 THEN RAISE_APPLICATION_ERROR(-20050, 'Il risultato della revisione è negativo pertanto deve avere data di scadenza NULL.');


END;

/

/*al momento dell'INSERIMENTO di una REVISIONE:
 - se il valore dell’attributo risultato è “false” si cambia lo stato del taxi associato in “non disponibile” 
 e si cambia lo stato di tutte le prenotazioni future associate in “pendente”*/

CREATE OR REPLACE TRIGGER trig46
AFTER INSERT ON REVISIONI
FOR EACH ROW
WHEN(new.Risultato = 0)

BEGIN

    UPDATE TAXI
    SET Stato = 'non disponibile'
    WHERE :new.FK_Taxi = TAXI.IDtaxi;

    --SE IL TAXI è STANDARD

    FOR prenotazione IN (SELECT *
                         FROM PRENOTAZIONESTANDARD JOIN PRENOTAZIONI ON PRENOTAZIONESTANDARD.FK_PRENOTAZIONE = PRENOTAZIONI.IDPRENOTAZIONE
                         WHERE :new.FK_Taxi = PRENOTAZIONESTANDARD.FK_Taxi AND PRENOTAZIONI.DATAORA > SYSDATE)
    LOOP
        
        UPDATE PRENOTAZIONI
        SET Stato = 'pendente'
        WHERE IDprenotazione = prenotazione.FK_Prenotazione;

    END LOOP;

    --SE IL TAXI è LUSSO

    FOR prenotazione IN (SELECT *
                         FROM PRENOTAZIONELUSSO
                         WHERE :new.FK_Taxi = PRENOTAZIONELUSSO.FK_Taxi)
    LOOP
        
        UPDATE PRENOTAZIONI
        SET Stato = 'pendente'
        WHERE prenotazione.FK_Prenotazione = PRENOTAZIONI.IDprenotazione AND PRENOTAZIONI.DataOra >= SYSDATE;

    END LOOP;

    --SE IL TAXI è ACCESSIBILE

    FOR prenotazione IN (SELECT *
                         FROM PRENOTAZIONEACCESSIBILE
                         WHERE :new.FK_Taxi = PRENOTAZIONEACCESSIBILE.FK_TaxiAccessibile)
    LOOP
        
        UPDATE PRENOTAZIONI
        SET Stato = 'pendente'
        WHERE prenotazione.FK_Prenotazione = PRENOTAZIONI.IDprenotazione AND PRENOTAZIONI.DataOra >= SYSDATE;

    END LOOP;

END;

/ 

--RICARICHE

/*Al momento in cui un UTENTE EFFETTUA una RICARICA:
 - l’importo deve essere maggiore di zero
 - la data deve essere la data corrente*/

CREATE OR REPLACE TRIGGER trig29
BEFORE INSERT ON RICARICHE
FOR EACH ROW
DECLARE
except51 EXCEPTION;
except52 EXCEPTION;

BEGIN

    IF(:new.Importo <= 0)

        THEN RAISE except51;
    
    END IF;

    IF(TRUNC(:new.Data) != TRUNC(SYSDATE))

        THEN RAISE except52;

    END IF;
    
    EXCEPTION
    WHEN except51 THEN RAISE_APPLICATION_ERROR(-20051, 'L importo della ricarica che si vuole inserire è minore o uguale a zero.');
    WHEN except52 THEN RAISE_APPLICATION_ERROR(-20052, 'La data della ricarica che si vuole inserire non è quella corrente.');
    
END;

/

--TAXI

/*al momento dell’INSERIMENTO del TAXI o della sua MODIFICA:
 - si controlla se l’autista referente ha la patente da meno di 3 anni, e in caso si controlla che il taxi a lui assegnato abbia cilindrata <=1400cc*/


CREATE OR REPLACE TRIGGER trig30
BEFORE INSERT OR UPDATE ON TAXI
FOR EACH ROW
WHEN (new.Cilindrata > 1400)
DECLARE
dataPatente DATE;
except53 EXCEPTION;

BEGIN

    SELECT DataPatente
    INTO dataPatente
    FROM AUTISTI
    WHERE AUTISTI.FK_Dipendente = :new.FK_Referente;

    IF( TRUNC(dataPatente) > TRUNC(SYSDATE) - (3*365))

        THEN RAISE except53;
    
    END IF;    
    
    EXCEPTION
    WHEN except53 THEN RAISE_APPLICATION_ERROR(-20053, 'La patente del referente scelto non è adatto per la cilindrata il suddetto taxi.');

END;

/

/*quando il TAXI cambia lo STATO da “prenotato” a “disponibile”:
 - si controlla che siano passati più di 10 minuti dall’orario della prenotazione corrente associata, altrimenti si fa fallire la modifica*/

CREATE OR REPLACE TRIGGER trig31
BEFORE UPDATE ON TAXI
FOR EACH ROW
WHEN (new.Stato = 'disponibile' AND old.Stato = 'prenotato')
DECLARE
countStandard NUMBER;
countLusso NUMBER;
countAccessibile NUMBER;
except54 EXCEPTION;

BEGIN

    countStandard := 0;
    countLusso := 0;
    countAccessibile := 0;

    SELECT COUNT(*)
    INTO countStandard
    FROM TAXISTANDARD ts
    WHERE ts.FK_TAXI = :new.IDTAXI;

    SELECT COUNT(*)
    INTO countLusso
    FROM TAXILUSSO tl
    WHERE tl.FK_TAXI = :new.IDTAXI;

    SELECT COUNT(*)
    INTO countAccessibile
    FROM TAXIACCESSIBILE ta
    WHERE ta.FK_TAXI = :new.IDTAXI;

    IF(countStandard > 0) THEN

        FOR prenotazione IN (SELECT *
                             FROM PRENOTAZIONI p JOIN PRENOTAZIONESTANDARD ps ON p.IDPRENOTAZIONE = ps.FK_PRENOTAZIONE
                             WHERE ps.FK_TAXI = :new.IDTAXI AND TRUNC(p.DATAORA)=TRUNC(SYSDATE))
        
        LOOP

            IF(prenotazione.DataOra < SYSDATE AND prenotazione.DataOra + (1/144) > SYSDATE) THEN

                RAISE except54;

            END IF;

        END LOOP;

    END IF;

    IF(countLusso > 0) THEN

        FOR prenotazione IN (SELECT *
                             FROM PRENOTAZIONI p JOIN PRENOTAZIONELUSSO pl ON p.IDPRENOTAZIONE = pl.FK_PRENOTAZIONE
                             WHERE pl.FK_TAXI = :new.IDTAXI AND TRUNC(p.DATAORA)=TRUNC(SYSDATE))
        
        LOOP

            IF(prenotazione.DataOra < SYSDATE AND prenotazione.DataOra + (1/144) > SYSDATE) THEN

                RAISE except54;

            END IF;

        END LOOP;

    END IF;

    IF(countAccessibile > 0) THEN

        FOR prenotazione IN (SELECT *
                             FROM PRENOTAZIONI p JOIN PRENOTAZIONEACCESSIBILE pa ON p.IDPRENOTAZIONE = pa.FK_PRENOTAZIONE
                             WHERE pa.FK_TAXIACCESSIBILE = :new.IDTAXI AND TRUNC(p.DATAORA)=TRUNC(SYSDATE))
        
        LOOP

            IF(prenotazione.DataOra < SYSDATE AND prenotazione.DataOra + (1/144) > SYSDATE) THEN

                RAISE except54;

            END IF;

        END LOOP;

    END IF;

    EXCEPTION
    WHEN except54 THEN RAISE_APPLICATION_ERROR(-20054, 'Il taxi di cui si vuole modificare lo stato sta ancora aspettando il cliente. Attendere 10 minuti dall inizio della prenotazione in corso.');

END;

/

/*quando CAMBIA lo STATO di un TAXI IN “non disponibile”:
le prenotazioni a esso associate in data corrente cambiano stato in “pendenti” e quindi si setta a NULL la chiave esterna che riferisce al taxi*/

CREATE OR REPLACE TRIGGER trig47
AFTER UPDATE ON TAXI
FOR EACH ROW
WHEN (new.Stato = 'non disponibile')

BEGIN 

    -- SE è UN TAXI STANDARD

    FOR prenotazione IN (SELECT *
                         FROM PRENOTAZIONESTANDARD pr JOIN PRENOTAZIONI p ON pr.FK_Prenotazione = p.IDprenotazione
                         WHERE :new.IDtaxi = pr.FK_Taxi)

    LOOP

        IF (prenotazione.DataOra > SYSDATE) THEN 

            UPDATE PRENOTAZIONI
            SET Stato = 'pendente'
            WHERE PRENOTAZIONI.IDprenotazione = prenotazione.IDprenotazione;

            UPDATE PRENOTAZIONESTANDARD
            SET FK_Taxi = NULL
            WHERE FK_Prenotazione = prenotazione.IDprenotazione;

        END IF;

    END LOOP;

    -- SE è UN TAXI DI LUSSO

    FOR prenotazione IN (SELECT *
                         FROM PRENOTAZIONELUSSO pr JOIN PRENOTAZIONI p ON pr.FK_Prenotazione = p.IDprenotazione
                         WHERE :new.IDtaxi = pr.FK_Taxi)

    LOOP

        IF (prenotazione.DataOra > SYSDATE) THEN 
                
            UPDATE PRENOTAZIONI
            SET Stato = 'pendente'
            WHERE PRENOTAZIONI.IDprenotazione = prenotazione.IDprenotazione;

            UPDATE PRENOTAZIONELUSSO
            SET FK_Taxi = NULL
            WHERE FK_Prenotazione = prenotazione.IDprenotazione;

        END IF;

    END LOOP;

    -- SE è UN TAXI ACCESSIBILE

    FOR prenotazione IN (SELECT *
                         FROM PRENOTAZIONEACCESSIBILE pr JOIN PRENOTAZIONI p ON pr.FK_Prenotazione = p.IDprenotazione
                         WHERE :new.IDtaxi = pr.FK_TaxiAccessibile)

    LOOP

        IF (prenotazione.DataOra > SYSDATE) THEN 

            UPDATE PRENOTAZIONI
            SET Stato = 'pendente'
            WHERE PRENOTAZIONI.IDprenotazione = prenotazione.IDprenotazione;

            UPDATE PRENOTAZIONEACCESSIBILE
            SET FK_TaxiAccessibile = NULL
            WHERE FK_Prenotazione = prenotazione.IDprenotazione;

        END IF;

    END LOOP;

END;

/

--TAXI ACCESSIBILE

/* all’INSERIMENTO di un TAXI ACCESSIBILE:
 - il numero di posti del taxi associato deve essere <=3.
 */

CREATE OR REPLACE TRIGGER trig32
BEFORE INSERT ON TAXIACCESSIBILE
FOR EACH ROW
DECLARE
NumeroPosti NUMBER;
except55 EXCEPTION;

BEGIN

    SELECT Nposti
    INTO NumeroPosti
    FROM TAXI
    WHERE TAXI.IDtaxi = :new.FK_Taxi;

    IF (NumeroPosti > 3)

        THEN RAISE except55;

    END IF;

    EXCEPTION
    WHEN except55 THEN RAISE_APPLICATION_ERROR(-20055, 'Il numero dei posti assegnati al taxi accessibile è maggiore di 3.');

END;

/

--TURNI

/*al momento della creazione di un turno:
si controlla se l’autista ha la patente da meno di 3 anni, e in caso si controlla che il taxi a lui assegnato abbia cilindrata <=1400cc (-20056)
*/

CREATE OR REPLACE TRIGGER trig33
BEFORE INSERT ON TURNI
FOR EACH ROW
DECLARE
dataPatenteAutista DATE;
cilindrataTaxiAssociato NUMBER;
dataScadenzaPatente DATE;
statotaxiassegnato VARCHAR2(15);
conteggio NUMBER;
eccezionePatente NUMBER;
codicepatente VARCHAR2(15);
except56 EXCEPTION;
BEGIN
    
    --autista neopatentato non può guidare taxi di cilindrata >1400
    SELECT a.DataPatente INTO dataPatenteAutista
    FROM AUTISTI a
    WHERE a.FK_Dipendente=:new.FK_Autista;
    IF ABS(MONTHS_BETWEEN(dataPatenteAutista, :NEW.DataOraInizio)/12)<3 THEN
        SELECT t.Cilindrata INTO cilindrataTaxiAssociato
        FROM TAXI t
        WHERE t.IDtaxi=:new.FK_Taxi;
        IF cilindrataTaxiAssociato>1400 THEN
          RAISE except56;
        END IF;
    END IF;

    --validità della patente
    SELECT MAX(p.Scadenza) 
    INTO dataScadenzaPatente
    FROM PATENTI p
    WHERE p.FK_AUTISTA = :new.FK_Autista;

    IF dataScadenzaPatente < SYSDATE THEN

        UPDATE PATENTI
        SET Validita = 0
        WHERE FK_AUTISTA = :new.FK_Autista;

        UPDATE PRENOTAZIONI p
        SET p.Stato='pendente'
        WHERE TRUNC(p.DataOra)=TRUNC(SYSDATE) AND p.IDprenotazione IN (SELECT p.IDprenotazione 
                                                                        FROM PRENOTAZIONI p 
                                                                        LEFT JOIN PRENOTAZIONESTANDARD PS ON P.IDprenotazione = PS.FK_Prenotazione
                                                                        LEFT JOIN TAXISTANDARD TS ON PS.FK_Taxi = TS.FK_Taxi
                                                                        LEFT JOIN PRENOTAZIONEACCESSIBILE PA ON P.IDprenotazione = PA.FK_Prenotazione
                                                                        LEFT JOIN TAXIACCESSIBILE TA ON PA.FK_TaxiAccessibile = TA.FK_Taxi
                                                                        LEFT JOIN PRENOTAZIONELUSSO PL ON P.IDprenotazione = PL.FK_Prenotazione
                                                                        LEFT JOIN TAXILUSSO TL ON PL.FK_Taxi = TL.FK_Taxi
                                                                        LEFT JOIN TURNI tu ON tu.FK_Taxi = COALESCE(TS.FK_Taxi, TA.FK_Taxi, TL.FK_Taxi)
                                                                        WHERE :new.FK_Autista= tu.FK_Autista);

        DELETE FROM TURNI
        WHERE FK_Autista = :new.FK_Autista AND DataOraInizio > SYSDATE;

    END IF;

    EXCEPTION
    WHEN except56 THEN RAISE_APPLICATION_ERROR(-20056, 'autista neopatentato');

END;

/

/*al momento della creazione di un turno:
il taxi e l’autista associato non devono essere associati ad un altro turno che abbia lo stesso periodo di orario con meno di due ore di margine (-20058)
la differenza tra l’orario di inizio del turno e l’orario di fine è di minimo 2 ore e massimo 6 ore. (-20060)
il taxi associato deve avere stato diverso da “non disponibile” (-20061)
la data del turno deve essere maggiore di un giorno dalla data odierna (-20062)*/


CREATE OR REPLACE TRIGGER trig34
BEFORE INSERT ON TURNI
FOR EACH ROW
DECLARE
statotaxiassegnato VARCHAR2(15);
conteggio NUMBER;
differenzaOrario NUMBER;
except62 EXCEPTION;
except61 EXCEPTION;
except60 EXCEPTION;
except58 EXCEPTION;

BEGIN
    --taxi e autista non presente in altri turni con orario sovrapposto
    SELECT COUNT(*) INTO conteggio
    FROM TURNI tu
    WHERE (tu.FK_Taxi=:new.FK_Taxi OR tu.FK_Autista=:new.FK_Autista) 
            AND ((tu.DataOraFine > (:new.DataOraInizio - 2/24)) AND (tu.DataOraInizio<(:new.DataOraFine + 2/24)));

    IF conteggio > 0 THEN

        RAISE except58;

    END IF; 
    
    differenzaOrario := (:new.DataOraFine - :new.DataOraInizio)*(24);

    --turno deve durare almeno due ore e al massimo 6 ore
    IF differenzaOrario < 2 OR differenzaOrario > 6 THEN

        RAISE except60;

    END IF;

    --taxi non deve avere stato non disponibile
    SELECT t.Stato INTO statotaxiassegnato
    FROM TAXI t
    WHERE t.IDtaxi=:new.FK_Taxi;

    IF statotaxiassegnato='non disponibile' THEN

      RAISE except61;

    END IF;

    --data del turno almeno un giorno dopo la data odierna
    IF(:new.DataOraInizio < (SYSDATE) + 1)

        THEN RAISE except62;

    END IF;

    EXCEPTION
      WHEN except58 THEN RAISE_APPLICATION_ERROR(-20058, 'Il taxi o l autista inseriti sono presenti in un altro turno il cui periodo si sovrappone a quello inserito.');
      WHEN except60 THEN RAISE_APPLICATION_ERROR(-20060, 'la durata di un turno deve essere di almeno due ore e al massimo 6');
      WHEN except61 THEN RAISE_APPLICATION_ERROR(-20061, 'il taxi inserito per il turno è non disponibile');
      WHEN except62 THEN RAISE_APPLICATION_ERROR(-20062, 'La data di inizio del turno è a meno di un giorno di distanza');
END;

/

/*Al momento dell’INSERIMENTO degli ORARI EFFETTIVI di INIZIO TURNO:
il taxi e l’autista associato non devono comparire in altri turni che hanno orario di inizio effettivo NOT NULL e orario di fine effettivo NULL. (-20063)
l’orario di inizio effettivo deve essere >= dell’orario di inizio previsto e <= dell’ora di fine prevista (-20065)*/

CREATE OR REPLACE TRIGGER trig35
BEFORE UPDATE on TURNI
FOR EACH ROW
WHEN (old.DataOraInizioEff IS NULL AND new.DataOraInizioEff IS NOT NULL)
DECLARE
conteggio NUMBER;
except63 EXCEPTION;
except65 EXCEPTION;
PRAGMA AUTONOMOUS_TRANSACTION;

BEGIN
    IF :new.DataOraInizioEff < :new.DataOraInizio THEN

      RAISE except65;

    END IF;

    SELECT COUNT(*) INTO conteggio
    FROM TURNI t
    WHERE (t.DataOraInizioEff IS NOT NULL) AND (t.DataOraFineEff IS NULL) AND (t.FK_Autista=:new.FK_Autista OR t.FK_Taxi=:new.FK_Taxi);

    IF conteggio>0 THEN

        RAISE except63;

    END IF;

    EXCEPTION
      WHEN except63 THEN RAISE_APPLICATION_ERROR(-20063, 'autista o taxi presenti in un altro turno in corso');
      WHEN except65 THEN RAISE_APPLICATION_ERROR(-20065, 'orario di inizio effettivo deve essere successivo a quello previsto');
END;

/

/*Nel momento in cui l’autista inserisce l’ora della fine effettiva del suo turno:
 - quest’ultima deve essere maggiore o uguale della data e ora di fine della sua ultima corsa + la sua durata. (-20066)
 - la data di inizio effettiva di un turno deve essere minore di un giorno o uguale della data di fine effettiva. (-20067)
 - non deve essere più di due ore successiva alla fine prevista (-20068)*/

CREATE OR REPLACE TRIGGER trig36
BEFORE UPDATE on TURNI
FOR EACH ROW
WHEN (old.DataOraFineEff IS NULL AND new.DataOraFineEff IS NOT NULL)
DECLARE
  countStandard NUMBER;
  countLusso NUMBER;
  countAccessibile NUMBER;
  fineCorsaMax DATE;
  ultimacnp NUMBER;
  ultimacp NUMBER;
  DurataUltimaCorsa NUMBER;
  DataOraUltimaCorsa DATE;
  except66 EXCEPTION;
  except67 EXCEPTION;
  except68 EXCEPTION;
BEGIN
    
    SELECT c1.IDcorsa INTO ultimacnp FROM CORSENONPRENOTATE c1 WHERE c1.DataOra = (SELECT MAX(c.DataOra)
    FROM CORSENONPRENOTATE c JOIN TURNI t ON c.FK_Standard=t.FK_Taxi
    WHERE :new.FK_Taxi=t.FK_Taxi AND t.DataOraInizioEff IS NOT NULL AND t.DataOraFineEff IS NULL);

    SELECT COUNT(*)
    INTO countStandard
    FROM TAXISTANDARD ts
    WHERE :new.FK_Taxi = ts.FK_Taxi;
    IF (countStandard > 0) THEN
        SELECT c1.FK_Prenotazione INTO ultimacp FROM CORSEPRENOTATE c1 WHERE c1.DataOra = (SELECT MAX(c.DataOra)
        FROM CORSEPRENOTATE c JOIN PRENOTAZIONESTANDARD p ON c.FK_Prenotazione=p.FK_Prenotazione
        WHERE :new.FK_taxi = p.FK_Taxi);
    ELSE
      SELECT COUNT(*)
      INTO countLusso
      FROM TAXILUSSO tl
      WHERE :new.FK_Taxi = tl.FK_Taxi;
      IF (countLusso > 0) THEN
        SELECT c1.FK_Prenotazione INTO ultimacp FROM CORSEPRENOTATE c1 WHERE c1.DataOra = (SELECT MAX(c.DataOra)
        FROM CORSEPRENOTATE c JOIN PRENOTAZIONELUSSO p ON c.FK_Prenotazione=p.FK_Prenotazione
        WHERE :new.FK_taxi = p.FK_Taxi);
      ELSE
        SELECT COUNT(*)
        INTO countAccessibile
        FROM TAXIACCESSIBILE ta
        WHERE :new.FK_Taxi = ta.FK_Taxi;
        IF (countAccessibile > 0) THEN
          SELECT c1.FK_Prenotazione INTO ultimacp FROM CORSEPRENOTATE c1 WHERE c1.DataOra = (SELECT MAX(c.DataOra)
          FROM CORSEPRENOTATE c JOIN PRENOTAZIONEACCESSIBILE p ON c.FK_Prenotazione=p.FK_Prenotazione
          WHERE :new.FK_taxi = p.FK_TaxiAccessibile);
        END IF;
      END IF;
    END IF;

    SELECT c.DataOra, c.Durata INTO DataOraUltimaCorsa, DurataUltimaCorsa
    FROM CORSENONPRENOTATE c
    WHERE c.IDcorsa=ultimacnp;
    IF (DurataUltimaCorsa IS NULL) OR (:new.DataOraFineEff<DataOraUltimaCorsa+NUMTODSINTERVAL(DurataUltimaCorsa, 'MINUTE'))
    THEN RAISE except66;
    END IF;

    SELECT c.DataOra, c.Durata INTO DataOraUltimaCorsa, DurataUltimaCorsa
    FROM CORSEPRENOTATE c
    WHERE c.FK_Prenotazione=ultimacnp;
    IF (DurataUltimaCorsa IS NULL) OR (:new.DataOraFineEff < DataOraUltimaCorsa+NUMTODSINTERVAL(DurataUltimaCorsa, 'MINUTE'))
    THEN RAISE except66;
    END IF;

    IF (TRUNC(:new.DataOraFineEff) - TRUNC(:new.DataOraInizioEff)) >1 THEN
        RAISE except67;
    END IF;

    IF :new.DataOraFineEff - :old.DataOraFine > INTERVAL '2' HOUR
    THEN RAISE except68;
    END IF;


  EXCEPTION
    WHEN except66 THEN RAISE_APPLICATION_ERROR(-20066, 'orario di fine effettivo deve essere successivo a quello in cui è finita ultima corsa');
    WHEN except67 THEN RAISE_APPLICATION_ERROR(-20067, 'inizio effettivo deve essere il giorno precedente o il giorno stesso della fine effettiva');
    WHEN except68 THEN RAISE_APPLICATION_ERROR(-20068, 'fine effettiva deve essere entro due ore dalla fine prevista');
END;

/

--DIPENDENTI

/* al momento della DISATTIVAZIONE di un DIPENDENTE:
 - impostare la fine sessione su sysdate per tutte le sessioni associate al dipendente disattivato */

CREATE OR REPLACE TRIGGER trig44
AFTER UPDATE ON DIPENDENTI
FOR EACH ROW
WHEN (new.Stato = 0)
BEGIN

    UPDATE SESSIONIDIPENDENTI
    SET FINESESSIONE = SYSDATE
    WHERE IDDIPENDENTE = :new.Matricola AND FINESESSIONE IS NULL;


END;