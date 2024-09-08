CREATE OR REPLACE VIEW CorseNPAutista AS
    SELECT d.Matricola, d.Nome, d.Cognome, count(*) as NumeroCorse
    FROM CorseNonPrenotate cnp, TaxiStandard ts, Taxi t, Turni tu, Autisti a, Dipendenti d
    WHERE
        cnp.FK_Standard = ts.FK_Taxi AND
        ts.FK_Taxi = t.IDtaxi AND
        tu.FK_Taxi = t.IDtaxi AND
        tu.FK_Autista = a.FK_Dipendente AND
        a.FK_Dipendente = d.Matricola
    GROUP BY d.Matricola, d.Nome, d.Cognome;

CREATE OR REPLACE VIEW UtilizzoTaxiStandard AS
SELECT t.IDtaxi, t.Targa, COUNT(*) AS Uso
FROM TAXI t
JOIN PRENOTAZIONESTANDARD ps ON t.IDtaxi = ps.FK_Taxi
LEFT JOIN CORSEPRENOTATE cp ON ps.FK_Prenotazione = cp.FK_Prenotazione
LEFT JOIN CORSENONPRENOTATE cnp ON ps.FK_Prenotazione = cnp.FK_Standard
GROUP BY t.IDtaxi, t.Targa;

CREATE OR REPLACE VIEW UtilizzoTaxiAccessibili AS
SELECT t.IDtaxi, t.Targa, COUNT(*) AS Uso
FROM TAXI t
JOIN PRENOTAZIONEACCESSIBILE pa ON t.IDtaxi = pa.FK_TaxiAccessibile
LEFT JOIN CORSEPRENOTATE cp ON pa.FK_Prenotazione = cp.FK_Prenotazione
GROUP BY t.IDtaxi, t.Targa;

CREATE OR REPLACE VIEW UtilizzoTaxiLusso AS
SELECT t.IDtaxi, t.Targa, COUNT(*) AS Uso
FROM TAXI t
JOIN PRENOTAZIONELUSSO pl ON t.IDtaxi = pl.FK_Taxi
LEFT JOIN CORSEPRENOTATE cp ON pl.FK_Prenotazione = cp.FK_Prenotazione
GROUP BY t.IDtaxi, t.Targa;

CREATE OR REPLACE VIEW PrenotazioniPerTipoTaxi AS
SELECT
    COUNT(*) AS TotalePrenotazioni,
    SUM(CASE WHEN ps.FK_Taxi IS NOT NULL THEN 1 ELSE 0 END) AS PrenotazioniStandard,
    SUM(CASE WHEN pa.FK_TaxiAccessibile IS NOT NULL THEN 1 ELSE 0 END) AS PrenotazioniAccessibili,
    SUM(CASE WHEN pl.FK_Taxi IS NOT NULL THEN 1 ELSE 0 END) AS PrenotazioniLusso
FROM
    PRENOTAZIONI p
    LEFT JOIN PRENOTAZIONESTANDARD ps ON p.IDprenotazione = ps.FK_Prenotazione
    LEFT JOIN PRENOTAZIONEACCESSIBILE pa ON p.IDprenotazione = pa.FK_Prenotazione
    LEFT JOIN PRENOTAZIONELUSSO pl ON p.IDprenotazione = pl.FK_Prenotazione;


CREATE OR REPLACE VIEW PercentualeUtilizzoTaxi AS
SELECT
    (PrenotazioniStandard / TotalePrenotazioni) * 100 AS PercentualeStandard,
    (PrenotazioniAccessibili / TotalePrenotazioni) * 100 AS PercentualeAccessibili,
    (PrenotazioniLusso / TotalePrenotazioni) * 100 AS PercentualeLusso
FROM
    PrenotazioniPerTipoTaxi;

CREATE OR REPLACE VIEW UtilizzoTaxiStandardAutista AS
SELECT d.Matricola, d.Nome, d.Cognome, t.IDtaxi, t.Targa, COUNT(*) AS NumeroCorse
FROM DIPENDENTI d
JOIN AUTISTI a ON a.FK_Dipendente=d.Matricola
JOIN TURNI tu ON tu.FK_Autista=a.FK_Dipendente
JOIN TAXI t ON t.IDtaxi=tu.FK_Taxi
JOIN PRENOTAZIONESTANDARD p ON t.IDtaxi = p.FK_Taxi
LEFT JOIN CORSEPRENOTATE cp ON p.FK_Prenotazione = cp.FK_Prenotazione AND tu.DataOraInizioEff<=cp.DataOra AND tu.DataOraFineEff>=cp.DataOra+NUMTODSINTERVAL(cp.Durata, 'MINUTE')
LEFT JOIN CORSENONPRENOTATE cnp ON t.IDTAXI = cnp.FK_Standard AND tu.DataOraInizioEff<=cnp.DataOra AND tu.DataOraFineEff>=cnp.DataOra+NUMTODSINTERVAL(cnp.Durata, 'MINUTE')
GROUP BY d.Matricola, d.Nome, d.Cognome, t.IDtaxi, t.Targa;

CREATE OR REPLACE VIEW UtilizzoTaxiAccessibiliAutista AS
SELECT d.Matricola, d.Nome, d.Cognome, t.IDtaxi, t.Targa, COUNT(*) AS NumeroCorse
FROM DIPENDENTI d
JOIN AUTISTI a ON a.FK_Dipendente=d.Matricola
JOIN TURNI tu ON tu.FK_Autista=a.FK_Dipendente
JOIN TAXI t ON t.IDtaxi=tu.FK_Taxi
JOIN PRENOTAZIONEACCESSIBILE p ON t.IDtaxi = p.FK_TaxiAccessibile
LEFT JOIN CORSEPRENOTATE cp ON p.FK_Prenotazione = cp.FK_Prenotazione AND tu.DataOraInizioEff<=cp.DataOra AND tu.DataOraFineEff>=cp.DataOra+NUMTODSINTERVAL(cp.Durata, 'MINUTE')
GROUP BY d.Matricola, d.Nome, d.Cognome, t.IDtaxi, t.Targa;

CREATE OR REPLACE VIEW UtilizzoTaxiLussoAutista AS
SELECT d.Matricola, d.Nome, d.Cognome, t.IDtaxi, t.Targa, COUNT(*) AS NumeroCorse
FROM DIPENDENTI d
JOIN AUTISTI a ON a.FK_Dipendente=d.Matricola
JOIN TURNI tu ON tu.FK_Autista=a.FK_Dipendente
JOIN TAXI t ON t.IDtaxi=tu.FK_Taxi
JOIN PRENOTAZIONELUSSO p ON t.IDtaxi = p.FK_Taxi
LEFT JOIN CORSEPRENOTATE cp ON p.FK_Prenotazione = cp.FK_Prenotazione AND tu.DataOraInizioEff<=cp.DataOra AND tu.DataOraFineEff>=cp.DataOra+NUMTODSINTERVAL(cp.Durata, 'MINUTE')
GROUP BY d.Matricola, d.Nome, d.Cognome, t.IDtaxi, t.Targa;

CREATE OR REPLACE VIEW UtilizzoTaxiAutista AS
SELECT * FROM UtilizzoTaxiStandardAutista
UNION ALL
SELECT * FROM UtilizzoTaxiAccessibiliAutista
UNION ALL
SELECT * FROM UtilizzoTaxiLussoAutista;


create or replace package gruppo2 as
    u_user constant  varchar(20):='test2324';
    u_root constant varchar(20):=u_user || '.utenter2324';
    link constant varchar(50) := 'http://131.114.73.203:8080/apex/';


 ----------------------  TAXI  ----------------------

    PROCEDURE visualizzaTaxi(
        id_ses in SessioniDipendenti.IDSessione%type,
        t_fkreferente in Taxi.FK_Referente%type default null,
        t_targa in Taxi.Targa%type default null,
        t_cilindrata in Taxi.Cilindrata%type default null,
        t_nposti in Taxi.Nposti%type default null,
        t_npersonedisabili in TaxiAccessibile.NpersoneDisabili%type default null,
        t_km in Taxi.Km%type default null,
        t_stato in Taxi.Stato%type default null,
        t_tariffa in Taxi.Tariffa%type default null,
        t_tipo in varchar2 default 'non_spec',
        t_stato_order in varchar2 default 'non_spec',
        t_cilindrata_min in Taxi.Cilindrata%type default null,
        t_cilindrata_max in Taxi.Cilindrata%type default null,
        t_km_min in Taxi.Km%type default null,
        t_km_max in Taxi.Km%type default null,
        message in varchar default '',
        negMessage in varchar default null
    );

    PROCEDURE visualizzaUnTaxi(
        id_ses in SESSIONIDIPENDENTI.IDsessione%type,
        t_IDtaxi in TAXI.IDTAXI%type default null,
        t_fkreferente in TAXI.FK_REFERENTE%type default null,
        t_targa in TAXI.TARGA%type default null,
        t_cilindrata in TAXI.CILINDRATA%type default null,
        t_nposti in TAXI.NPOSTI%type default null,
        t_npersonedisabili in TAXIACCESSIBILE.NPERSONEDISABILI%type default null,
        t_km in TAXI.KM%type default null,
        t_stato in TAXI.STATO%type default null,
        t_tariffa in TAXI.TARIFFA%type default null,
        message in varchar2 default ''
    );

    PROCEDURE modificaTaxi(
        id_ses in SessioniDipendenti.IDSessione%type,
        t_idtaxi in TAXI.IDTAXI%type default null,
        t_tipo in varchar2 default null,
        t_accessibili in TAXIACCESSIBILE.NPERSONEDISABILI%type default null,
        t_fkreferente in TAXI.FK_REFERENTE%type default null,
        t_targa in TAXI.TARGA%type default null,
        t_cilindrata in TAXI.CILINDRATA%type default null,
        t_nposti in TAXI.NPOSTI%type default null,
        t_km in TAXI.KM%type default null,
        t_stato in TAXI.STATO%type default null,
        t_tariffa in TAXI.TARIFFA%type default null,
        message in varchar default ''
    );

    PROCEDURE checkModificheTaxi(
        id_ses in SessioniDipendenti.IDSessione%type,
        t_idtaxi in TAXI.IDTAXI%type default null,
        t_accessibili in TAXIACCESSIBILE.NPERSONEDISABILI%type default null,
        t_fkreferente in TAXI.FK_REFERENTE%type default null,
        t_targa in TAXI.TARGA%type default null,
        t_cilindrata in TAXI.CILINDRATA%type default null,
        t_nposti in TAXI.NPOSTI%type default null,
        t_km in TAXI.KM%type default null,
        t_oldKm in TAXI.KM%type default null,
        t_stato in TAXI.STATO%type default null,
        t_tariffa in TAXI.TARIFFA%type default null,
        t_tipo in varchar2 default null
    );

    PROCEDURE updateTaxi(
        id_ses in SessioniDipendenti.IDSessione%type,
        t_idtaxi in TAXI.IDTAXI%type default null,
        t_tipo in varchar2 default null,
        t_accessibili in TAXIACCESSIBILE.NPERSONEDISABILI%type default null,
        t_fkreferente in TAXI.FK_REFERENTE%type default null,
        t_targa in TAXI.TARGA%type default null,
        t_cilindrata in TAXI.CILINDRATA%type default null,
        t_nposti in TAXI.NPOSTI%type default null,
        t_km in TAXI.KM%type default null,
        t_stato in TAXI.STATO%type default null,
        t_tariffa in TAXI.TARIFFA%type default null,
        message in varchar default ''
    );

    PROCEDURE inserisciTipologiaTaxi(
        id_ses in SessioniDipendenti.IDSessione%type,
        t_tipologia in VARCHAR default 'STANDARD'
    );

    PROCEDURE inserisciTaxi(
        id_ses in SessioniDipendenti.IDSessione%type,
        t_tipologia in VARCHAR,
        t_referente_matr in Taxi.FK_Referente%type default null,
        t_targa in Taxi.Targa%type default null,
        t_cilindrata in Taxi.Cilindrata%type default null,
        t_nposti in Taxi.Nposti%type default null,
        t_km in Taxi.Km%type default null,
        t_tariffa in Taxi.Tariffa%type default null,
        t_NpersoneDisabili in TaxiAccessibile.NpersoneDisabili%type default null,
        t_IDoptionals in varchar2 default null,
        posMessage in VARCHAR default null,
        negMessage in varchar default null
    );

    PROCEDURE checkTaxi(
        id_ses in SessioniDipendenti.IDSessione%type,
        t_tipologia in VARCHAR,
        t_referente_matr in Taxi.FK_Referente%type,
        t_targa in Taxi.Targa%type,
        t_cilindrata in Taxi.Cilindrata%type,
        t_nposti in Taxi.Nposti%type,
        t_km in Taxi.Km%type,
        t_tariffa in Taxi.Tariffa%type,
        t_NpersoneDisabili in TaxiAccessibile.NpersoneDisabili%type default null,
        t_IDoptionals in varchar2 default null
    );

    PROCEDURE insertTaxiRevisione(
        id_ses in SessioniDipendenti.IDSessione%type,
        t_tipologia in VARCHAR,
        t_referente_matr in Taxi.FK_Referente%type,
        t_targa in Taxi.Targa%type,
        t_cilindrata in Taxi.Cilindrata%type,
        t_nposti in Taxi.Nposti%type,
        t_km in Taxi.Km%type,
        t_tariffa in Taxi.Tariffa%type,
        t_NpersoneDisabili in TaxiAccessibile.NpersoneDisabili%type default null,
        t_IDoptionals in varchar2 default null,
        -- REVISIONE
        DataRev in varchar2,
        ScadRev in varchar2,
        AzioneRev in AZIONICORRETTIVE.Azione%type
    );


----------------------  OPTIONALS  ----------------------

    procedure visualizzaOptionals(
        id_ses in SessioniDipendenti.IDSessione%type,
        o_Nome in Optionals.Nome%type default null,
        o_IDtaxi in Taxi.IDtaxi%type default null,
        o_Data_min in varChar2 default null,
        o_Data_max in varChar2 default null,
        o_Ora_min in varChar2 default null,
        o_Ora_max in varChar2 default null,
        negMessage in varchar default null,
        posMessage in varchar default null
    );

    PROCEDURE addOptionals(
        id_ses in SessioniDipendenti.IDSessione%type,
        o_Nome in Optionals.Nome%type default null,
        o_IDtaxi in Taxi.IDtaxi%type default null,
        o_IDoptionals in Optionals.IDoptionals%type default null
    );

    PROCEDURE removeOptionals(
        id_ses in SessioniDipendenti.IDSessione%type,
        o_Nome in Optionals.Nome%type default null,
        o_IDtaxi in Taxi.IDtaxi%type default null,
        o_IDoptionals in Optionals.IDoptionals%type default null
    );

    PROCEDURE modificaOptionals(
        id_ses in SessioniDipendenti.IDSessione%type,
        o_id in Optionals.IDoptionals%type default null,
        o_IDtaxi in Taxi.IDtaxi%type default null,
        message in VARCHAR default ''
    );

    PROCEDURE checkOptionals(
        id_ses in SessioniDipendenti.IDSessione%type,
        o_nome in Optionals.Nome%type default '',
        o_id in Optionals.IDOptionals%type default null,
        o_IDtaxi in Taxi.IDtaxi%type default null
    );

    PROCEDURE updateOptionals(
        id_ses in SessioniDipendenti.IDSessione%type,
        o_nome in Optionals.Nome%type default '',
        o_id in Optionals.IDOptionals%type default null,
        o_IDtaxi in Taxi.IDtaxi%type default null
    );

    PROCEDURE inserisciOptional(
        id_ses in SessioniDipendenti.IDSessione%type,
        o_IDtaxi in Taxi.IDtaxi%type default null,
        o_name in VARCHAR default null,
        t_tipologia in VARCHAR default null,
        t_referente_matr in Taxi.FK_Referente%type default null,
        t_targa in Taxi.Targa%type default null,
        t_cilindrata in Taxi.Cilindrata%type default null,
        t_nposti in Taxi.Nposti%type default null,
        t_km in Taxi.Km%type default null,
        t_tariffa in Taxi.Tariffa%type default null,
        t_IDoptionals in varchar2 default null,
        message in VARCHAR default ''
    );

    PROCEDURE checkInserimentoOptional(
        id_ses in SessioniDipendenti.IDSessione%type,
        o_IDtaxi in Taxi.IDtaxi%type default null,
        o_name in Optionals.Nome%type default '',
        t_tipologia in VARCHAR default null,
        t_referente_matr in Taxi.FK_Referente%type default null,
        t_targa in Taxi.Targa%type default null,
        t_cilindrata in Taxi.Cilindrata%type default null,
        t_nposti in Taxi.Nposti%type default null,
        t_km in Taxi.Km%type default null,
        t_tariffa in Taxi.Tariffa%type default null,
        t_IDoptionals in varchar2 default null
    );

    PROCEDURE insertOptional(
        id_ses in SessioniDipendenti.IDSessione%type,
        o_IDtaxi in Taxi.IDtaxi%type default null,
        o_name in Optionals.Nome%type,
        t_tipologia in VARCHAR default null,
        t_referente_matr in Taxi.FK_Referente%type default null,
        t_targa in Taxi.Targa%type default null,
        t_cilindrata in Taxi.Cilindrata%type default null,
        t_nposti in Taxi.Nposti%type default null,
        t_km in Taxi.Km%type default null,
        t_tariffa in Taxi.Tariffa%type default null,
        t_IDoptionals in varchar2 default null
    );


----------------------  CORSE NON PRENOTATE   ----------------------

    PROCEDURE visualizzaCorseNonPrenotate(
        id_ses in SessioniDipendenti.IDSessione%type,
        c_Data_min in varChar2 default null,
        c_Data_max in varChar2 default null,
        c_Ora_min in varChar2 default null,
        c_Ora_max in varChar2 default null,
        c_Durata_min in CorseNonPrenotate.Durata%type default null,
        c_Durata_max in CorseNonPrenotate.Durata%type default null,
        c_Importo_min in CorseNonPrenotate.Importo%type default null,
        c_Importo_max in CorseNonPrenotate.Importo%type default null,
        c_Passeggeri_min in CorseNonPrenotate.Passeggeri%type default null,
        c_Passeggeri_max in CorseNonPrenotate.Passeggeri%type default null,
        c_Km_min in CorseNonPrenotate.Km%type default null,
        c_Km_max in CorseNonPrenotate.Km%type default null,
        c_Partenza in CorseNonPrenotate.Partenza%type default null,
        c_Arrivo in CorseNonPrenotate.Arrivo%type default null,
        c_Targa in Taxi.Targa%type default null,
        c_Matricola in Dipendenti.Matricola%type default null,
        --c_Nome in Dipendenti.Nome%type default null,
        --c_Cognome in Dipendenti.Cognome%type default null,
        negMessage in varchar default null,
        posMessage in varchar default null
    );

    PROCEDURE inserisciCorseNonPrenotate(
        id_ses in SessioniDipendenti.IDSessione%type,
        c_passeggeri in CorseNonPrenotate.Passeggeri%type default null,
        c_partenza in CorseNonPrenotate.Partenza%type default null,
        c_message in VARCHAR default ''
    );

    PROCEDURE checkInserimentoCNP(
        id_ses in SessioniDipendenti.IDSessione%type,
        c_passeggeri in CorseNonPrenotate.Passeggeri%type,
        c_partenza in CorseNonPrenotate.Partenza%type
    );

    PROCEDURE insertCorseNonPrenotate(
        id_ses in SessioniDipendenti.IDSessione%type,
        c_passeggeri in CorseNonPrenotate.Passeggeri%type,
        c_partenza in CorseNonPrenotate.Partenza%type,
        c_autista in Autisti.FK_Dipendente%type
    );

    FUNCTION isDaCompletare(
        c_id in CorseNonPrenotate.IDcorsa%type
    ) RETURN BOOLEAN;

    PROCEDURE completaCorseNonPrenotate(
        id_ses in SessioniDipendenti.IDSessione%type,
        c_id in CorseNonPrenotate.IDcorsa%type,
        kmpercorsi in CorseNonPrenotate.Km%type default null,
        luogoarrivo in CorseNonPrenotate.Arrivo%type default null,
        message in VARCHAR default null
    );

    PROCEDURE checkCompletaCNP(
        id_ses in SessioniDipendenti.IDSessione%type,
        c_id in CorseNonPrenotate.IDCorsa%type,
        c_kmpercorsi in CorseNonPrenotate.KM%type default null,
        c_luogoarrivo in CorseNonPrenotate.Arrivo%type default null,
        message in VARCHAR default null
    );

    PROCEDURE updateCNPCompletamento(
        id_ses in SessioniDipendenti.IDSessione%type,
        c_id in CorseNonPrenotate.IDCorsa%type,
        c_kmpercorsi in CorseNonPrenotate.KM%type default null,
        c_luogoarrivo in CorseNonPrenotate.Arrivo%type default null,
        message in VARCHAR default null
    );

    PROCEDURE modificaCorseNonPrenotate(
        id_ses in SessioniDipendenti.IDSessione%type,
        c_id in CorseNonPrenotate.IDcorsa%type,
        c_kmpercorsi in CorseNonPrenotate.Km%type default null,
        c_luogoarrivo in CorseNonPrenotate.Arrivo%type default null,
        c_passeggeri in CorseNonPrenotate.Passeggeri%type default null,
        c_luogopartenza in CorseNonPrenotate.Partenza%type default null,
        message in VARCHAR default null
    );

    PROCEDURE checkModificaCNP(
        id_ses in SessioniDipendenti.IDSessione%type,
        c_id in CorseNonPrenotate.IDCorsa%type,
        c_kmpercorsi in CorseNonPrenotate.KM%type default null,
        c_luogoarrivo in CorseNonPrenotate.Arrivo%type default null,
        c_passeggeri in CorseNonPrenotate.Passeggeri%type default null,
        c_luogopartenza in CorseNonPrenotate.Partenza%type default null,
        message in VARCHAR default null
    );

    PROCEDURE updateCNP(
        id_ses in SessioniDipendenti.IDSessione%type,
        c_id in CorseNonPrenotate.IDCorsa%type,
        c_kmpercorsi in CorseNonPrenotate.KM%type default null,
        c_luogoarrivo in CorseNonPrenotate.Arrivo%type default null,
        c_passeggeri in CorseNonPrenotate.Passeggeri%type default null,
        c_luogopartenza in CorseNonPrenotate.Partenza%type default null,
        message in VARCHAR default null
    );

    ----------STATISTICHE-----------
    PROCEDURE visualizzaCorseNPAutista(
        id_ses in SessioniDipendenti.IDSessione%type,
        a_Matricola in Dipendenti.Matricola%type default null,
        a_nome in Dipendenti.Nome%type default null,
        a_Cognome in Dipendenti.Cognome%type default null,
        a_NumCorseMin in Number default null,
        a_NumCorseMax in Number default null,
        a_Data_min in varChar2 default null,
        a_Data_max in varChar2 default null,
        a_Ora_min in varChar2 default null,
        a_Ora_max in varChar2 default null,
        a_Durata_min in CorseNonPrenotate.Durata%type default null,
        a_Durata_max in CorseNonPrenotate.Durata%type default null,
        a_Importo_min in CorseNonPrenotate.Importo%type default null,
        a_Importo_max in CorseNonPrenotate.Importo%type default null
    );

    PROCEDURE visualizzaBestCNPAutista(
        id_ses in SessioniDipendenti.IDSessione%type,
        a_Matricola in Dipendenti.Matricola%type default null,
        a_Nome in Dipendenti.Nome%type default null,
        a_Cognome in Dipendenti.Cognome%type default null,
        a_NumCorseMin in Number default null,
        a_NumCorseMax in Number default null,
        a_Data_min in varChar2 default null,
        a_Data_max in varChar2 default null,
        a_Ora_min in varChar2 default null,
        a_Ora_max in varChar2 default null,
        a_Durata_min in CorseNonPrenotate.Durata%type default null,
        a_Durata_max in CorseNonPrenotate.Durata%type default null,
        a_Importo_min in CorseNonPrenotate.Importo%type default null,
        a_Importo_max in CorseNonPrenotate.Importo%type default null
    );
    PROCEDURE utilizzoTaxi(
        id_ses in SessioniDipendenti.IDSessione%type,
        t_targa in TAXI.Targa%type default null,
        t_tipo in varchar2 default null
    );

    PROCEDURE VisualizzaUsoTaxiAutista(
        id_ses in SessioniDipendenti.IDSessione%type,
        a_Matricola in Dipendenti.Matricola%type default null,
        a_Nome in Dipendenti.Nome%type default null,
        a_Cognome in Dipendenti.Cognome%type default null,
        at_CorseMin in UtilizzoTaxiAutista.NumeroCorse%type default null,
        at_CorseMax in UtilizzoTaxiAutista.NumeroCorse%type default null,
        t_Targa in Taxi.Targa%type default null
    );

end gruppo2;
