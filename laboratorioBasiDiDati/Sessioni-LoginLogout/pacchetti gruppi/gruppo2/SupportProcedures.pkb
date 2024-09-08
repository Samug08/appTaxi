create or replace package BODY  g2S AS
    PROCEDURE initialization(
        id_ses IN SessioniDipendenti.IDSessione%TYPE,
        i_tab in VARCHAR2,
        i_h1 in VARCHAR2
    ) IS
    begin
        gui.ApriPagina(i_tab, id_ses);
        gui.ACAPO();
        gui.AggiungiIntestazione(i_h1, 'h1');
        gui.ACAPO(4);
    end initialization;

    FUNCTION canModify_CNP(
        id_ses IN SessioniDipendenti.IDSessione%TYPE,
        id_corsa IN CorseNonPrenotate.IDcorsa%TYPE
    ) RETURN BOOLEAN IS
    v_count INTEGER;
    BEGIN
        SELECT COUNT(*) INTO v_count
        FROM CorseNonPrenotate cnp, TaxiStandard ts, Taxi t, Turni tu
        WHERE cnp.IDcorsa = id_corsa AND
            cnp.FK_Standard = ts.FK_Taxi AND
            ts.FK_Taxi = t.IDtaxi AND
            tu.FK_Taxi = t.IDtaxi AND
            tu.FK_Autista = SessionHandler.getIDuser(id_ses) AND
            cnp.DataOra >= tu.DataOraInizio AND
            cnp.DataOra <= tu.DataOraFine AND
            SYSDATE <= tu.DataOraFine + INTERVAL '1' DAY;

        IF v_count > 0 THEN
            RETURN TRUE;
        END IF;

        RETURN FALSE;
    END canModify_CNP;

    PROCEDURE resetFilter(
        url in VARCHAR,
        text in varchar2 default null,
        id_ses in SessioniDipendenti.IDSessione%type,
        o_IDtaxi in Taxi.IDtaxi%type default null,
        t_tipo in varchar2 default null,
        o_Nome in Optionals.Nome%type default null,
        o_Data_min in varChar2 default null,
        o_Data_max in varChar2 default null,
        o_Ora_min in varChar2 default null,
        o_Ora_max in varChar2 default null
    ) IS
    BEGIN
        gui.ApriFormFiltro(gruppo2.u_root || url);
        gui.AggiungiCampoFormHidden(tipo => 'number', nome => 'id_ses', value => id_ses);
        if o_IDtaxi IS NOT NULL THEN
            gui.AggiungiCampoFormHidden(tipo => 'number', nome => 'o_IDtaxi', value => o_IDtaxi);
        end if;
        if t_tipo IS NOT NULL THEN
            gui.AggiungiCampoFormHidden(tipo => 'text', nome => 't_tipo', value => t_tipo);
        end if;
        if o_Nome IS NOT NULL THEN
            gui.AggiungiCampoFormHidden(tipo => 'text', nome => 'o_Nome', value => o_Nome);
        end if;
        if o_Data_min IS NOT NULL THEN
            gui.AggiungiCampoFormHidden(tipo => 'text', nome => 'o_Data_min', value => o_Data_min);
        end if;
        if o_Data_max IS NOT NULL THEN
            gui.AggiungiCampoFormHidden(tipo => 'text', nome => 'o_Data_max', value => o_Data_max);
        end if;
        if o_Ora_min IS NOT NULL THEN
            gui.AggiungiCampoFormHidden(tipo => 'text', nome => 'o_Ora_min', value => o_Ora_min);
        end if;
        if o_Ora_max IS NOT NULL THEN
            gui.AggiungiCampoFormHidden(tipo => 'text', nome => 'o_Ora_max', value => o_Ora_max);
        end if;
        if text IS NOT NULL THEN
            gui.AggiungiCampoFormFiltro(tipo => 'submit', nome => '', placeholder => text);
        ELSE
            gui.AggiungiCampoFormFiltro(tipo => 'submit', nome => '', placeholder => 'Reset filtro');
        end if;

        gui.chiudiFormFiltro();

        gui.ACAPO();
    END resetFilter;

    FUNCTION splitString(
        str IN VARCHAR2,
        delimiter IN VARCHAR2
    ) RETURN gui.stringArray IS
        result gui.stringArray := gui.stringArray();
        startPos PLS_INTEGER := 1;
        endPos PLS_INTEGER;
    BEGIN
        IF str IS NULL OR LENGTH(str) = 0 THEN
            RETURN result;
        END IF;

        LOOP
            endPos := INSTR(str, delimiter, startPos);
            IF endPos = 0 THEN
                result.extend;
                result(result.count) := SUBSTR(str, startPos);
                EXIT;
            END IF;
            result.extend;
            result(result.count) := SUBSTR(str, startPos, endPos - startPos);
            startPos := endPos + LENGTH(delimiter);
        END LOOP;
        RETURN result;
    END splitString;

    FUNCTION checkMatricola(
        t_referente_matr in Taxi.FK_Referente%type
    ) RETURN BOOLEAN IS
    v_count INTEGER;
    BEGIN
        SELECT COUNT(*) INTO v_count
        FROM Dipendenti d, Autisti a
        WHERE   d.Matricola = a.FK_Dipendente AND
                d.Matricola = t_referente_matr AND
                d.Stato = 1 AND
                SYSDATE <= (
                    SELECT MAX(Scadenza)
                    FROM Patenti p
                    WHERE   p.FK_Autista = t_referente_matr AND
                            p.Validita = 1);

        IF v_count > 0 THEN
            RETURN TRUE;
        END IF;

        RETURN FALSE;
    END checkMatricola;

    FUNCTION checkTarga(
        t_targa in Taxi.Targa%type
    ) RETURN BOOLEAN IS
    v_count INTEGER;
    BEGIN
        SELECT COUNT(*) INTO v_count
        FROM Taxi t
        WHERE t.Targa = t_targa;

        IF v_count > 0 THEN
            RETURN FALSE;
        END IF;

        RETURN TRUE;
    END checkTarga;

    FUNCTION checkCilindrata(
        t_cilindrata in Taxi.Cilindrata%type,
        t_referente_matr in Taxi.FK_Referente%type
    ) RETURN BOOLEAN IS
    v_count INTEGER;
    BEGIN
        SELECT COUNT(*) INTO v_count
        FROM Autisti a
        WHERE   a.FK_Dipendente = t_referente_matr AND
                (
                    t_cilindrata <= 1400 OR
                    SYSDATE >= ADD_MONTHS(a.DataPatente, 12)
                );

        IF (v_count > 0 AND t_cilindrata > 0) THEN
            RETURN TRUE;
        END IF;

        RETURN FALSE;
    END checkCilindrata;

    FUNCTION listAutisti RETURN gui.stringArray IS
    autisti_list gui.stringArray;
    BEGIN
        SELECT  d.Matricola || ' - ' || d.Nome || ' ' || d. Cognome
        BULK COLLECT INTO autisti_list
        FROM Dipendenti d, Autisti a
        WHERE d.Matricola = a.FK_Dipendente
        ORDER BY Matricola;

        RETURN autisti_list;
    END listAutisti;

    FUNCTION listIDAutisti RETURN gui.stringArray IS
    autisti_list gui.stringArray;
    BEGIN
        SELECT  d.Matricola
        BULK COLLECT INTO autisti_list
        FROM Dipendenti d, Autisti a
        WHERE d.Matricola = a.FK_Dipendente
        ORDER BY Matricola;

        RETURN autisti_list;
    END listIDAutisti;

    FUNCTION listOptionals RETURN gui.stringArray IS
    optionals_list gui.stringArray;
    BEGIN
        SELECT  OPTIONALS.Nome
        BULK COLLECT INTO optionals_list
        FROM Optionals
        ORDER BY Nome;

        RETURN optionals_list;
    END listOptionals;

    FUNCTION listIdOptionals RETURN gui.stringArray IS
    IDoptionals_list gui.stringArray;
    BEGIN
        SELECT  OPTIONALS.IDoptionals
        BULK COLLECT INTO IDoptionals_list
        FROM Optionals
        ORDER BY Nome;

        RETURN IDoptionals_list;
    END listIdOptionals;
    -----------OPTIONALS------------
    /*FUNCTION checkTaxiWithOptionals(optionals_list IN gui.STRINGARRAY) RETURN BOOLEAN IS
        v_count NUMBER;
    BEGIN
        -- Conta il numero di taxi che possiedono tutti gli optional specificati
        SELECT COUNT(*) INTO v_count
        FROM TAXILUSSO tl,POSSIEDETAXILUSSO ptl,OPTIONALS o
        WHERE tl.FK_Taxi = ptl.FK_TaxiLusso AND
            ptl.FK_Optionals = o.IDoptionals AND
            o.Nome MEMBER OF optionals_list;

        -- Restituisce TRUE se almeno un taxi soddisfa i requisiti, altrimenti FALSE
        RETURN v_count > 0;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN FALSE; -- Se non ci sono taxi che soddisfano i requisiti, restituisci FALSE
    END checkTaxiWithOptionals;*/ -- DA RIVEDERE

    FUNCTION vieneSoddifatta(
        o_IDtaxi IN Taxi.IDtaxi%type,
        o_IDoptionals IN OPTIONALS.IDoptionals%type
    ) RETURN BOOLEAN
    IS
        v_count NUMBER;
    BEGIN
        -- Controlla se esiste un altro taxi (diverso da o_IDtaxi) che possiede o_IDoptionals
        -- e ha uno stato diverso da 'non disponibile'
        SELECT COUNT(*) INTO v_count
        FROM TAXI t
        JOIN POSSIEDETAXILUSSO ptl ON t.IDtaxi = ptl.FK_TaxiLusso
        WHERE t.IDtaxi != o_IDtaxi
        AND ptl.FK_Optionals = o_IDoptionals
        AND t.Stato != 'non disponibile';

        -- Se il conteggio è maggiore di 0, significa che esiste un taxi soddisfacente
        IF v_count > 0 THEN
            RETURN true;
        ELSE
            RETURN false;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            -- Gestione di altre eccezioni
            RETURN false;
    END;

    FUNCTION rifiutaPrenotazioni(
        o_IDtaxi IN Taxi.IDtaxi%type,
        o_IDoptionals IN OPTIONALS.IDoptionals%type,
        o_stato IN Prenotazioni.Stato%type
    ) RETURN BOOLEAN
    IS
    BEGIN
        -- Imposta lo stato delle prenotazioni corrispondenti
        UPDATE PRENOTAZIONI p
            SET p.Stato = o_stato
            WHERE p.IDprenotazione IN (
                SELECT pl.FK_Prenotazione
                FROM RICHIESTEPRENLUSSO rpl
                JOIN PRENOTAZIONELUSSO pl ON rpl.FK_Prenotazione = pl.FK_Prenotazione
                WHERE pl.FK_Taxi = o_IDtaxi AND
                    rpl.FK_Optionals = o_IDoptionals AND
                    p.DataOra > SYSDATE
            );
            UPDATE PRENOTAZIONELUSSO
            SET FK_Taxi = NULL
            WHERE FK_Prenotazione IN (
                SELECT pl.FK_Prenotazione
                FROM RICHIESTEPRENLUSSO rpl
                JOIN PRENOTAZIONELUSSO pl ON rpl.FK_Prenotazione = pl.FK_Prenotazione
                JOIN PRENOTAZIONI p ON p.IDprenotazione = pl.FK_Prenotazione
                WHERE pl.FK_Taxi = o_IDtaxi AND
                    rpl.FK_Optionals = o_IDoptionals AND
                    p.DataOra > SYSDATE);

        RETURN true;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            -- Se non ci sono prenotazioni corrispondenti, restituisce true
            RETURN true;
        WHEN OTHERS THEN
            -- Gestione di altre eccezioni
            RETURN false;
    END rifiutaPrenotazioni;


    FUNCTION checkEqualsOldName(
        o_id in Optionals.Nome%type,
        o_nome in Optionals.Nome%type
    ) RETURN BOOLEAN IS
    oldName VARCHAR(50);
    BEGIN
        SELECT op.nome into oldName
        FROM Optionals op
        WHERE o_id = op.IDOptionals;

        IF LOWER(replace(oldName, ' ', ''))=LOWER(replace(o_nome, ' ', '')) THEN
            RETURN TRUE;
        END IF;

        RETURN FALSE;
    END checkEqualsOldName;

    FUNCTION checkNomeOptionals(
        o_nome in Optionals.Nome%type
    ) RETURN BOOLEAN IS
    same_name_count INTEGER;
    BEGIN
        SELECT count(*) INTO same_name_count
            FROM OPTIONALS op
            WHERE (LOWER(replace(o_nome, ' ', '')))=(LOWER(replace(op.Nome, ' ', '')));
        if same_name_count> 0 THEN
            RETURN FALSE;
        ELSE RETURN TRUE;
            END IF;
    END checkNomeOptionals;

    FUNCTION isReferente(
        matricola in Dipendenti.Matricola%type,
        idTaxi in Taxi.IDtaxi%type default null
    ) RETURN BOOLEAN IS
    v_count INTEGER;
    BEGIN
        IF idTaxi IS NOT NULL THEN
            SELECT COUNT(*) INTO v_count
            FROM Taxi t
            WHERE t.IDtaxi = isReferente.idTaxi AND
                t.FK_Referente = matricola;
        ELSE
            SELECT COUNT(*) INTO v_count
            FROM Taxi t
            WHERE t.FK_Referente = matricola;
        END IF;

        IF v_count > 0 THEN
            RETURN TRUE;
        END IF;

        RETURN FALSE;
    END ;

    FUNCTION isInTurno(
        c_autista in Autisti.FK_Dipendente%type
    ) RETURN BOOLEAN IS
    numRows number;
    BEGIN

        SELECT count(*) INTO numRows
        FROM Turni tu, Taxi t, TaxiStandard ts
        WHERE tu.FK_Autista = c_autista AND
            tu.FK_TAXI = t.IDTAXI AND
            t.IDTaxi = ts.FK_Taxi AND
            SYSDATE >=tu.DataOraInizioEff
                AND SYSDATE <= tu.DataOraFine;
        IF numRows = 1 THEN RETURN TRUE;
        ELSE RETURN FALSE;
        END IF;
    END;

    FUNCTION hasNoCorseAttive(
        c_autista in Autisti.FK_Dipendente%type
    ) RETURN BOOLEAN IS
    numCorseNP number;
    numCorse number;
    BEGIN
       SELECT COUNT(*) INTO numCorseNP
            FROM CorseNonPrenotate cnp, TaxiStandard ts, Taxi t, Turni tu
            WHERE cnp.FK_Standard = ts.FK_Taxi AND
                ts.FK_Taxi = t.IDtaxi AND
                tu.FK_Taxi = t.IDtaxi AND
                tu.FK_Autista = c_autista AND
                cnp.DataOra >= tu.DataOraInizio AND
                cnp.DataOra <= tu.DataOraFine AND
                cnp.Durata IS NULL;
        SELECT COUNT(*) INTO numCorse --da controllare
            FROM CorsePrenotate cp, Prenotazioni p, PrenotazioneStandard ps, PrenotazioneLusso pl, PrenotazioneAccessibile pa,
            TaxiStandard ts, TaxiAccessibile ta, TaxiLusso tl, Taxi t, Turni tu
            WHERE cp.FK_Prenotazione = p.IDprenotazione AND
               ((
                ps.FK_Prenotazione = p.IDprenotazione AND
                ps.FK_Taxi = ts.FK_Taxi AND
                t.IDTaxi = ts.FK_Taxi
               )
               OR
               (
                pl.FK_Prenotazione = p.IDprenotazione AND
                pl.FK_Taxi = tl.FK_Taxi AND
                t.IDTaxi = tl.FK_Taxi
               )
               OR
               (
                pa.FK_Prenotazione = p.IDprenotazione AND
                pa.FK_TaxiAccessibile = ta.FK_Taxi AND
                t.IDTaxi = ta.FK_Taxi
               )
               )  AND
                tu.FK_Taxi = t.IDtaxi AND
                tu.FK_Autista = c_autista AND
                cp.DataOra >= tu.DataOraInizio AND
                cp.DataOra <= tu.DataOraFine AND
                cp.Durata IS NULL;
        IF numCorseNP+numCorse>0 THEN RETURN FALSE;
        ELSE RETURN TRUE;
        END IF;
    END;

    FUNCTION checkNumPasseggeri(
        c_passeggeri in CorseNonPrenotate.Passeggeri%type,
        c_autista in Autisti.FK_Dipendente%type
    ) RETURN BOOLEAN IS
    numPasseggeriTaxi Taxi.Nposti%type;
    BEGIN
        SELECT t.Nposti INTO numPasseggeriTaxi
        FROM Turni tu, Taxi t
        WHERE tu.FK_Autista = c_autista AND
            tu.FK_Taxi = t.IDTaxi AND
            SYSDATE >=tu.DataOraInizioEff AND SYSDATE <= tu.DataOraFine;
        IF ( numPasseggeriTaxi<c_passeggeri OR c_passeggeri<=0) THEN
            RETURN FALSE;
        ELSE RETURN TRUE;
        END IF;

    END checkNumPasseggeri;

    FUNCTION getTaxiId(
        c_autista in Autisti.FK_Dipendente%type
    ) RETURN Taxi.IDTaxi%type
    IS
    taxiId Taxi.IDTaxi%type;
    BEGIN
        SELECT t.IDTaxi INTO taxiId
        FROM Turni tu, Taxi t
        WHERE tu.FK_Autista = c_autista AND
            tu.FK_TAXI = t.IDTAXI AND
            SYSDATE >=tu.DataOraInizioEff
                AND SYSDATE <= tu.DataOraFine;
        RETURN taxiId;

    END getTaxiId;


    FUNCTION countCorse(
        autista in Autisti.FK_Dipendente%type
    ) RETURN INTEGER
    IS
    numCorse INTEGER;
    BEGIN
          SELECT COUNT(*) as NumeroCorse INTO numCorse
            FROM CorseNonPrenotate cnp, TaxiStandard ts, Taxi t, Turni tu
            WHERE
                cnp.FK_Standard = ts.FK_Taxi AND
                ts.FK_Taxi = t.IDtaxi AND
                tu.FK_Taxi = t.IDtaxi AND
                tu.FK_Autista = autista AND
                cnp.DataOra >= tu.DataOraInizio AND
                cnp.DataOra <= tu.DataOraFine;
        RETURN numCorse;
    END countCorse;
    /*FUNCTION (

    ) RETURN BOOLEAN IS
    v_count INTEGER;
    BEGIN
        SELECT COUNT(*) INTO v_count
        FROM
        WHERE ;

        IF v_count > 0 THEN
            RETURN TRUE;
        END IF;

        RETURN FALSE;
    END ;*/

end g2S;