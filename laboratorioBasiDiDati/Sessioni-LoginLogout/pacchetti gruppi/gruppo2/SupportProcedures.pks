create or replace package g2S as

    PROCEDURE initialization(
        id_ses IN SessioniDipendenti.IDSessione%TYPE,
        i_tab in VARCHAR2,
        i_h1 in VARCHAR2
    );

    function canModify_CNP(
        id_ses IN SessioniDipendenti.IDSessione%TYPE,
        id_corsa IN CorseNonPrenotate.IDcorsa%TYPE
    ) return boolean;

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
    );

    FUNCTION splitString(
        str IN VARCHAR2,
        delimiter IN VARCHAR2
    ) RETURN gui.stringArray;

    FUNCTION checkMatricola(
        t_referente_matr in Taxi.FK_Referente%type
    ) RETURN BOOLEAN;

    FUNCTION checkTarga(
        t_targa in Taxi.Targa%type
    ) RETURN BOOLEAN;

    FUNCTION checkCilindrata(
        t_cilindrata in Taxi.Cilindrata%type,
        t_referente_matr in Taxi.FK_Referente%type
    ) RETURN BOOLEAN;

    FUNCTION listAutisti RETURN gui.stringArray;

    FUNCTION listIDAutisti RETURN gui.stringArray;

    FUNCTION listOptionals RETURN gui.stringArray;

    FUNCTION listIdOptionals RETURN gui.stringArray;

    FUNCTION vieneSoddifatta(
        o_IDtaxi IN Taxi.IDtaxi%type,
        o_IDoptionals IN OPTIONALS.IDoptionals%type
    ) RETURN BOOLEAN;

    FUNCTION rifiutaPrenotazioni(
        o_IDtaxi IN Taxi.IDtaxi%type,
        o_IDoptionals IN OPTIONALS.IDoptionals%type,
        o_stato IN Prenotazioni.Stato%type
    ) RETURN BOOLEAN;

    FUNCTION checkEqualsOldName(
        o_id in Optionals.Nome%type,
        o_nome in Optionals.Nome%type
    ) RETURN BOOLEAN;

    FUNCTION checkNomeOptionals(
        o_nome in Optionals.Nome%type
    ) RETURN BOOLEAN;

    FUNCTION isReferente(
        matricola in Dipendenti.Matricola%type,
        idTaxi in Taxi.IDtaxi%type default null
    ) RETURN BOOLEAN;

    FUNCTION isInTurno(
        c_autista in Autisti.FK_Dipendente%type
    ) RETURN BOOLEAN;

    FUNCTION hasNoCorseAttive(
        c_autista in Autisti.FK_Dipendente%type
    ) RETURN BOOLEAN;

    FUNCTION checkNumPasseggeri(
        c_passeggeri in CorseNonPrenotate.Passeggeri%type,
        c_autista in Autisti.FK_Dipendente%type
    ) RETURN BOOLEAN;

    FUNCTION getTaxiId(
        c_autista in Autisti.FK_Dipendente%type
    ) RETURN Taxi.IDTaxi%type;

    FUNCTION countCorse(
        autista in Autisti.FK_Dipendente%type
    ) RETURN INTEGER;

end g2S;