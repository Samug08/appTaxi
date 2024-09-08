create or replace package inserimentoDati as
	u_user constant varchar(100) := 'http://131.114.73.203:8080/apex/utenter2324';
	u_root constant varchar(100) := u_user || '.inserimentoDati';


PROCEDURE inizioTurni (
    idSess in SESSIONIDIPENDENTI.IDSESSIONE%TYPE,
    modifica in varchar2 default null
);

procedure fineTurni(
    idSess in SESSIONIDIPENDENTI.IDSESSIONE%TYPE,
    modifica in varchar2 default null
);


end inserimentoDati;