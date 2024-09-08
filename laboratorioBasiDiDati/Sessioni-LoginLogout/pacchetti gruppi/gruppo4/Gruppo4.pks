create or replace PACKAGE Gruppo4 as

u_root CONSTANT varchar2(255) := 'http://131.114.73.203:8080/apex/utenter2324';
URL CONSTANT varchar2(255):= u_root||'.gruppo4.';

--Michele
procedure StatisticheAutisti(
    IDSessione varchar2 default null,
    Errmsg varchar2 default null,
    MatricolaI Dipendenti.Matricola%TYPE default null,
    NomeI Dipendenti.Nome%TYPE default null,
    CognomeI Dipendenti.Cognome%TYPE default null,
    DataInI varchar2 default TO_CHAR(SYSDATE,'YYYY-MM-DD'),
    DataFinI varchar2 default TO_CHAR(SYSDATE,'YYYY-MM-DD')
);

procedure CoperturaTurni(
    IDSessione varchar2 default null,
    Errmsg varchar2 default null,
    DataInI varchar2 default TO_CHAR(SYSDATE,'YYYY-MM-DD'),
    DataFinI varchar2 default TO_CHAR(SYSDATE,'YYYY-MM-DD')
);

function toSameDay(
    data Date,
    ora varchar2
) return Date;

procedure visualizzazionePatenti(
    MatricolaI in Dipendenti.Matricola%TYPE default null,
    NomeI Dipendenti.Nome%TYPE default null,
    CognomeI Dipendenti.Cognome%TYPE default null,
    ValiditaI number default null,
    DataInI varchar2 default null,
    DataFinI varchar2 default null,
    idSessione varchar2 default null,
    msg varchar2 default null,
    err number default null
);

procedure inserimentoPatente(
    MatricolaI in Dipendenti.Matricola%TYPE default null,
    CodI in patenti.Codice%TYPE default null,
    RilascioI varchar2 default null,
    ScadenzaI varchar2 default null,
    ValiditaI number default null,
    idSessione varchar2 default null,
    msg varchar2 default null,
    err number default null
);

procedure invalidaPatente(
    CodI in patenti.Codice%TYPE default null,
    idSessione varchar2 default null
);

procedure modificaPatente(
    MatricolaI in Dipendenti.Matricola%TYPE default null,
    CodI in patenti.Codice%TYPE default null,
    CodOld in patenti.Codice%TYPE,
    RilascioI varchar2 default null,
    ScadenzaI varchar2 default null,
    ValiditaI number default null,
    idSessione varchar2 default null,
    msg varchar2 default null,
    err number default null
);

--Domenico

procedure visualizzazioneRevisione(
    Id_Taxi VARCHAR2 default null,
    RisultatoRev in Revisioni.Risultato%TYPE default null,
    InizioScadenzaRev in VARCHAR2 default null,
    ScadenzaRev in VARCHAR2 default null,
    idSessione varchar2 default null,
    popup varchar2 default null,
    idUserFiltro varchar2 default null,
    InizioDataRev varchar2 default null,
    FineDataRev varchar2 default null
);

PROCEDURE inserimentoRevisione(
    RisultatoRev IN revisioni.risultato%TYPE DEFAULT NULL, 
    DataRev varchar2 DEFAULT NULL,
    ScadenzaRev varchar2 DEFAULT NULL,
    AzioneRev IN AzioniCorrettive.Azione%TYPE DEFAULT NULL,
    TaxiRevisionato IN taxi.targa%TYPE DEFAULT NULL,
    successo varchar2 default null,
    errore varchar2 default null,
    azioneCheck varchar2 default null,
    idSessione varchar2 default null
);

PROCEDURE PrimaRevisione(
    t_referente_matr IN taxi.FK_Referente%TYPE,
    t_targa IN taxi.targa%TYPE,
    t_cilindrata in taxi.cilindrata%TYPE,
    t_nposti in taxi.nposti%TYPE,
    t_km in taxi.km%TYPE,
    t_tariffa in taxi.tariffa%TYPE,
    t_tipologia varchar2,
    t_NpersoneDisabili in taxiaccessibile.npersonedisabili%TYPE DEFAULT NULL,
    t_IDoptionals in varchar2 default null,
    idSessione varchar2
);

function inserisciPrimaRev(
    DataRev varchar2,
    ScadenzaRev varchar2,
    AzioneRev in AzioniCorrettive.Azione%TYPE default null,
    TaxiRevisionato in taxi.idtaxi%TYPE
) return boolean;

procedure modificaRevisione(
    t_targa varchar2 default null,
    RisultatoRev IN revisioni.risultato%TYPE default null,
    DataRev varchar2 default null,
    ScadenzaRev varchar2 default null,
    AzioneRev IN AzioniCorrettive.Azione%TYPE default null,
    idSessione varchar2 default null,
    modificato int default 0,
    successo varchar2 default null,
    errore varchar2 default null,
    idRev varchar2 default null
);

procedure statisticheRev(
    idSessione varchar2 default null,
    t_targa varchar2 default null,
    nomeRef varchar2 default null,
    cognomeRef varchar2 default null
);

procedure statisticheAzCorr(
    idSessione varchar2 default null
);

procedure inserimentoAzioniCorr(
    idSessione varchar2 default null,
    AzioneCorr varchar2 default null
);

procedure visualizzaAzioniCorr(
    successo varchar2 default null,
    errore varchar2 default null,
    idSessione varchar2 default null
);

procedure modificaAzioneCorr( 
    idSessione varchar2 default null,
    idAzioneOld varchar2 default null,
    AzioneNew varchar2 default null,
    successo varchar2 default null,
    errore varchar2 default null
);

--Danilo

procedure visualizzazioneDipendenti(
    VMatricola in Dipendenti.Matricola%TYPE default null,
    VNome in Dipendenti.Nome%TYPE default null,
    VCognome in Dipendenti.Cognome%TYPE default null,
    VDataNascita VARCHAR2 default null,
    VNtelefono VARCHAR2 default null,
    VSesso varchar default '',
    VStato VARCHAR default '1',
    VCF VARCHAR2 default '',
    VBonus VARCHAR2 default '',
    VIndirizzo Dipendenti.Indirizzo%TYPE default null,
    Ruolo VARCHAR2 default null,
    Neopatentato VARCHAR default null,
    StatoPatente NUMBER default 0,
    error NUMBER default 0,
    Submit VARCHAR2 default '',
    idSessione varchar2 default null
) ;

procedure cancellaDipendente(
    VMatricola in Dipendenti.Matricola%TYPE default null,
    idSessione varchar2 default null
);

procedure modificaDipendente(
    IMatricola in Dipendenti.Matricola%TYPE default null,
    VNome in Dipendenti.Nome%TYPE default null,
    VCognome in Dipendenti.Cognome%TYPE default null,
    VDataNascita VARCHAR2 default null,
    VNtelefono VARCHAR2 default null,
    VSesso varchar default '',
    VStato VARCHAR default '',
    VCF VARCHAR2 default '',
    VBonus VARCHAR2 default '',
    VIndirizzo Dipendenti.Indirizzo%TYPE default null,
    VEmailAziendale Dipendenti.EmailAziendale%TYPE default null,
    VEmail Dipendenti.Email%TYPE default NULL,
    VdataPatente VARCHAR2 default NULL,
    error NUMBER default 0,
    Ruolo VARCHAR2 default '',
    idSessione varchar2 default null
);

procedure updateDipendente(
    VMatricola in Dipendenti.Matricola%TYPE default null,
    VNome in Dipendenti.Nome%TYPE default null,
    VCognome in Dipendenti.Cognome%TYPE default null,
    VDataNascita VARCHAR2 default null,
    VNtelefono VARCHAR2 default null,
    VSesso varchar default null,
    VPassword Dipendenti.Password%TYPE default null,
    NPassword Dipendenti.Password%TYPE default null,
    VStato VARCHAR2 default null,
    VCF VARCHAR2 default null,
    VBonus VARCHAR2 default null,
    VIndirizzo Dipendenti.Indirizzo%TYPE default null,
    VEmailAziendale Dipendenti.EmailAziendale%TYPE default null,
    VEmail Dipendenti.Email%TYPE default null,
    Ruolo VARCHAR2 default null,
    VDataPatente VARCHAR2 default null,
    error NUMBER default 0,
    idSessione varchar2 default null
);

procedure visualizzaDipendente(
    IMatricola in Dipendenti.Matricola%TYPE default null,
    error NUMBER default 0,
    idSessione varchar2 default null
);

function stringToArray(string in varchar2, delimiter in varchar2 default ';') RETURN gui.StringArray;

--Carolina
procedure visualizzazioneTurni(    
    IDAutista in Dipendenti.Matricola%TYPE default null,
    NomeAutista in Dipendenti.Nome%TYPE default null,
    CognomeAutista in Dipendenti.Cognome%TYPE default null,
    Taxi in Taxi.IDtaxi%TYPE default null,
    DataInizio  varchar2 default null,
    Datafine  varchar2 default null,
    errore VARCHAR2 default null,
    successo varchar2 default null,
    IDSessione varchar2 default null
);

procedure modificaTurno(
    IDAutista in Dipendenti.Matricola%TYPE default null,
    Taxi in Taxi.IDtaxi%TYPE default null,
    DataInizio  varchar2 default null,
    Datafine  varchar2 default null,
    errore varchar2 default null,
    IDSessione varchar2 default null
); 


procedure verificaModifica(
    IDAutista in Dipendenti.Matricola%TYPE default null,
    Taxi in Taxi.IDtaxi%TYPE default null,
    DataInizioPrec varchar2 default null,
    IDPrec in Dipendenti.Matricola%type default null,
    TaxiPrec in Taxi.IDtaxi%type default null,
    DataFinePrec varchar2 default null,
    DataInizio  varchar2 default null,
    DataFine  varchar2 default null,
    IDSessione varchar2 default null
);

procedure eliminaTurno(
    IDAutista in Turni.FK_Autista%TYPE default null,
    Taxi in Taxi.IDtaxi%TYPE default null,
    DataInizio  varchar2 default null,
    IDSessione varchar2 default null
);

procedure inserimentoTurni(
    IDAutista in Turni.FK_Autista%TYPE default null,
    Taxi in Taxi.IDtaxi%TYPE default null,
    DataInizio  varchar2 default null,
    Datafine  varchar2 default null,
    errore varchar2 default null,
    IDSessione varchar2 default null
);

procedure turniAutista(
    Taxi in Taxi.IDtaxi%TYPE default null,
    DataInizio  varchar2 default null,
    errore varchar2 default null,
    successo varchar2 default null,
    IDSessione varchar2 default null
);

procedure inizioTurno(
    IDAutista in Dipendenti.Matricola%TYPE default null,
    Taxi in Taxi.IDtaxi%TYPE default null,
    DataInizio  varchar2 default null,
    DataFine varchar2 default null,
    IDSessione varchar2 default null
);

procedure fineTurno(
    IDAutista in Dipendenti.Matricola%TYPE default null,
    Taxi in Taxi.IDtaxi%TYPE default null,
    DataInizioEff varchar2 default null,
    DataFine  varchar2 default null,
    IDSessione varchar2 default null
);

procedure mediaTurni(
    noman in Dipendenti.Nome%Type default null,
    cogman in Dipendenti.Cognome%type default null,
    sesman varchar2 default '',
    nomaut in Dipendenti.Nome%type default null,
    cogaut in Dipendenti.Cognome%type default null,
    sesaut varchar2 default '',
    errore varchar2 default null,
    idSessione varchar2 default null
);

end Gruppo4;
/
grant execute on Gruppo4 to anonymous;

--Viste Domenico
CREATE OR REPLACE VIEW VistaRevisioniTaxiRef AS
SELECT 
    t.Targa AS Targa,
    SUM(CASE WHEN r.Risultato = 1 THEN 1 ELSE 0 END) AS Revisioni_Passate,
    SUM(CASE WHEN r.Risultato = 0 THEN 1 ELSE 0 END) AS Revisioni_Fallite,
    t.FK_Referente as Referente,
    d.Nome as Nome,
    d.Cognome as Cognome
FROM 
    Revisioni r
JOIN 
    Taxi t ON r.FK_Taxi = t.IdTaxi
JOIN
    Dipendenti d ON t.FK_Referente = d.Matricola
GROUP BY 
    t.Targa, t.FK_Referente, d.Nome, d.Cognome
ORDER BY d.Nome;

CREATE OR REPLACE VIEW AzioniCorrView AS
    SELECT ac.Azione as Azione, COUNT(ar.FK_Revisione) as NumRevisioni
    FROM AzioniCorrettive ac
    LEFT JOIN AzioniRevisione ar ON ac.IDAzione = ar.FK_Azione
    GROUP BY ac.Azione
    ORDER BY NumRevisioni DESC;

CREATE OR REPLACE VIEW NumRevSenzaAzioniView AS
    SELECT count(*) as Numero
    FROM Revisioni
    WHERE IdRevisione NOT IN (SELECT FK_Revisione FROM AzioniRevisione)
    ORDER BY idRevisione;

--Viste Carolina
create or replace view MigAut(autista, numTurni,oreTurni) as 
select t.FK_Autista, count(*), sum(DataOraFine-DataOraInizio)
from turni t
group by t.FK_Autista;

create or replace view TurniMan(manager, totMan, ore) as
select t.FK_Manager, count(*), sum(DataOraFine-DataOraInizio)
from turni t 
group by t.FK_Manager;
