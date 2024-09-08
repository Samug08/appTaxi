-----------------------Leonardi-------------------------
create or replace view corsestandard as
	select dataora,
	       count(*) as numerocorsestandard
	  from (
		select cp.dataora
		  from corseprenotate cp
		  join prenotazioni p
		on p.idprenotazione = cp.fk_prenotazione
		  join prenotazionestandard ps
		on ps.fk_prenotazione = p.idprenotazione
		union all
		select dataora
		  from corsenonprenotate
	) corse
	 group by dataora;
create or replace view corseaccessibili as
	select dataora,
	       count(*) as numerocorseaccessibili
	  from (
		select cp.dataora
		  from corseprenotate cp
		  join prenotazioni p
		on p.idprenotazione = cp.fk_prenotazione
		  join prenotazioneaccessibile pa
		on pa.fk_prenotazione = p.idprenotazione
	) corse
	 group by dataora;
create or replace view corselusso as
	select dataora,
	       count(*) as numerocorselusso
	  from (
		select cp.dataora
		  from corseprenotate cp
		  join prenotazioni p
		on p.idprenotazione = cp.fk_prenotazione
		  join prenotazionelusso pl
		on pl.fk_prenotazione = p.idprenotazione
	) corse
	 group by dataora;
create or replace view statisticheafflusso as
	select '1' as id,
	       cs.dataora as ora,
	       cs.numerocorsestandard as ncorsestandard,
	       ca.numerocorseaccessibili as ncorseaccessibili,
	       cl.numerocorselusso as ncorselusso
	  from corsestandard cs,
	       corseaccessibili ca,
	       corselusso cl
	 group by cs.dataora,
	          cl.numerocorselusso,
	          cs.numerocorsestandard,
	          ca.numerocorseaccessibili
	 order by ora;

----------------------Caporale--------------------------
create or replace view countcorsepnp as
	select giorno,
	       corsepren,
	       corsenonpren
	  from (
		select count(*) as corsepren,
		       to_char(
			       cp.dataora,'YYYY-MM-DD'
		       ) as giorno
		  from corseprenotate cp
		  join prenotazionestandard ps
		on cp.fk_prenotazione = ps.fk_prenotazione
		 where to_char(
			cp.dataora,'YYYY-MM-DD'
		) < to_char(
			sysdate,'YYYY-MM-DD'
		)
		 group by to_char(
			cp.dataora,'YYYY-MM-DD'
		)
	) full
	  join (
		select count(*) as corsenonpren,
		       to_char(
			       cnp.dataora,'YYYY-MM-DD'
		       ) as giornonp
		  from corsenonprenotate cnp
		 where to_char(
			cnp.dataora,'YYYY-MM-DD'
		) < to_char(
			sysdate,'YYYY-MM-DD'
		)
		 group by to_char(
			cnp.dataora,'YYYY-MM-DD'
		)
	)
	on giorno = giornonp;


create or replace package gruppo1 as
	u_user constant varchar(20) := 'utenter2324';
	u_root constant varchar(20) := u_user || '.gruppo1';
	nopermessi exception;--Errore sul ruolo relativo alla sessione
	prenannrif exception;
	prennonmodificabile exception;
	prennonesiste exception;
	prenpassata exception;
	prengiamodificata exception;
	taxinonesiste exception;
	erroreparametri exception;
	taxinonassegnabile exception;
	erroreconvenzioni exception;
	nonesistecorsa exception;
	esistecorsanonterminata exception;
	errorepasseggeri exception;
	errorekm exception;
	nonesistecorsa exception;
	esistecorsaterminata exception;
	errorekm exception;
	nonesistecorsa exception;
	errorekm exception;
	preniddati exception;

-----------------------------------LEONARDI----------------------------------------
	procedure vispren (
		p_id             in prenotazioni.idprenotazione%type default null,
		p_data_min       varchar2 default null,
		p_data_max       varchar2 default null,
		p_ora_min        varchar2 default null,
		p_ora_max        varchar2 default null,
		p_partenza       in prenotazioni.luogopartenza%type default null,
		p_persone        in prenotazioni.npersone%type default null,
		p_arrivo         in prenotazioni.luogoarrivo%type default null,
		p_stato          in prenotazioni.stato%type default null,
		p_durata         in prenotazioni.durata%type default null,
		p_modificata     in prenotazioni.modificata%type default null,
		p_tipo           in nonanonime.tipo%type default null,
		p_categoria      in varchar2 default null,
		p_idcliente      in clienti.idcliente%type default null,
		p_targa          in taxi.targa%type default null,
		p_visprenboolean in integer default null,
		p_idsess         in sessioniclienti.idsessione%type default null
	);
	procedure inspren (
		p_idsess                in sessioniclienti.idsessione%type default null,
		p_idcliente             in clienti.idcliente%type default null,
		p_telefono              in anonimetelefoniche.ntelefono%type default null,
		p_dataora               varchar2 default null,
		p_partenza              in prenotazioni.luogopartenza%type default null,
		p_persone               in prenotazioni.npersone%type default null,
		p_arrivo                in prenotazioni.luogoarrivo%type default null,
		p_durata                in prenotazioni.durata%type default null,
		p_convenzionicumulabili in varchar2 default null,
		p_convenzione           in convenzioni.idconvenzione%type default null,
		p_optionals             in varchar2 default null,
		p_disabili              in prenotazioneaccessibile.npersonedisabili%type default null,
		p_stato                 in prenotazioni.stato%type default 'pendente',
		p_id_taxi               in taxi.idtaxi%type default null,
		p_visprenboolean        in integer default null,
		p_insconvboolean        in integer default 0
	);
	procedure loadstats (
		p_idsess   in sessioniclienti.idsessione%type default null,
		p_dataorai in varchar2 default null,
		p_dataoraf in varchar2 default null,
		p_interval in integer default null
	);

--------------------------------Ceccotti--------------------------------------

	procedure visualizzaprenotazionipendenti (
		p_idsess       in sessionidipendenti.idsessione%type default '-1',
		p_id           in prenotazioni.idprenotazione%type default null,
		p_data1        in varchar2 default null,
		p_data2        in varchar2 default null,
		p_partenza     in prenotazioni.luogopartenza%type default null,
		p_persone      in prenotazioni.npersone%type default null,
		p_arrivo       in prenotazioni.luogoarrivo%type default null,
		p_durata       in prenotazioni.durata%type default null,
		p_filtersubmit in varchar2 default null,
		p_ordina       in varchar2 default null,
		p_ascdesc      in varchar2 default null,
		p_accetta_id   in prenotazioni.idprenotazione%type default null,
		p_accetta      in varchar2 default null,
		p_offset       in int default 0
	);

	procedure visprenassegnatetaxi (
		p_idsess       in sessionidipendenti.idsessione%type default '-1',
		p_id           in prenotazioni.idprenotazione%type default null,
		p_data1        in varchar2 default null,
		p_data2        in varchar2 default null,
		p_partenza     in prenotazioni.luogopartenza%type default null,
		p_persone      in prenotazioni.npersone%type default null,
		p_arrivo       in prenotazioni.luogoarrivo%type default null,
		p_durata       in prenotazioni.durata%type default null,
		p_accetta_id   in prenotazioni.idprenotazione%type default null,
		p_accetta      in varchar2 default null,
		p_filtersubmit in varchar2 default null
	);

	procedure errorpage (
		p_idsess in sessionidipendenti.idsessione%type,
		p_errmsg in varchar2
	);

	procedure viscorsetaxiriferiti (
		p_idsess          in sessionidipendenti.idsessione%type default '-1',
		p_id_prenotazione in corseprenotate.fk_prenotazione%type default null,
		p_data1           in varchar2 default null,
		p_data2           in varchar2 default null,
		p_persone         in corseprenotate.passeggeri%type default null,
		p_durata          in corseprenotate.durata%type default null,
		p_km              in corseprenotate.km%type default null,
		p_importo         in corseprenotate.importo%type default null,
		p_tipo            in varchar2 default null,
		p_ordina          in varchar2 default null,
		p_ascdesc         in varchar2 default null,
		p_filtersubmit    in varchar2 default null,
		p_msgviscorsepren in number default null,
		p_offset          in int default 0
	);

	procedure accettaprenotazione (
		p_idsess     in sessionidipendenti.idsessione%type default '-1',
		p_accetta_id in prenotazioni.idprenotazione%type,
		p_tipo_taxi  in varchar2,
		p_id_taxi    in taxi.idtaxi%type,
		p_id_turno   in varchar2
	);

	procedure modificacorsaprenotata (
		p_idsess     in sessionidipendenti.idsessione%type default '-1',
		p_id         in corseprenotate.fk_prenotazione%type default null,
		p_km         in corseprenotate.km%type default null,
		p_passeggeri in corseprenotate.passeggeri%type default null,
		p_url        in varchar2 default null
	);

	procedure statcorsemaieffettuate (
		p_idsess in sessionidipendenti.idsessione%type default '-1'
	);

-----------------------------------CAPORALE----------------------------------------
	procedure visprenpenfut (
		p_id          in prenotazioni.idprenotazione%type default null,
		p_data_min    varchar2 default null,
		p_data_max    varchar2 default null,
		p_ora_min     varchar2 default null,
		p_ora_max     varchar2 default null,
		p_partenza    in prenotazioni.luogopartenza%type default null,
		p_persone_min in prenotazioni.npersone%type default null,
		p_persone_max in prenotazioni.npersone%type default null,
		p_arrivo      in prenotazioni.luogoarrivo%type default null,
		p_durata_min  in prenotazioni.durata%type default null,
		p_durata_max  in prenotazioni.durata%type default null,
		p_modificata  in prenotazioni.modificata%type default null,
		p_categoria   varchar2 default null,
		p_idsess      in sessionidipendenti.idsessione%type default null
	);

	procedure viscorsepren (
		p_id_prenotazione corseprenotate.fk_prenotazione%type default null,
		p_data_min        varchar2 default null,
		p_data_max        varchar2 default null,
		p_ora_min         varchar2 default null,
		p_ora_max         varchar2 default null,
		p_partenza        in prenotazioni.luogopartenza%type default null,
		p_arrivo          in prenotazioni.luogoarrivo%type default null,
		p_durata_min      corseprenotate.durata%type default null,
		p_durata_max      corseprenotate.durata%type default null,
		p_importo_min     corseprenotate.importo%type default null,
		p_importo_max     corseprenotate.importo%type default null,
		p_passeggeri_min  corseprenotate.passeggeri%type default null,
		p_passeggeri_max  corseprenotate.passeggeri%type default null,
		p_km_min          corseprenotate.km%type default null,
		p_km_max          corseprenotate.km%type default null,
		p_taxi            taxi.idtaxi%type default null,
		p_categoria       varchar2 default null,
		p_tipo            varchar2 default null,
		p_id_autista      autisti.fk_dipendente%type default null,
		p_id_operatore    operatori.fk_dipendente%type default null,
		p_id_cliente      clienti.idcliente%type default null,
		p_msgviscorsepren number default null,
		p_idsess          in sessionidipendenti.idsessione%type default null
	);

	procedure taxichesodd (
		p_id_prenotazione in prenotazioni.idprenotazione%type default null,
		p_dataora         varchar2 default null,
		p_partenza        in prenotazioni.luogopartenza%type default null,
		p_persone         in prenotazioni.npersone%type default null,
		p_arrivo          in prenotazioni.luogoarrivo%type default null,
		p_disabili        in prenotazioneaccessibile.npersonedisabili%type default null,
		p_optionals       varchar2 default null,
		p_idcliente       in clienti.idcliente%type default null,
		p_telefono        in anonimetelefoniche.ntelefono%type default null,
		p_id_taxi         in taxi.idtaxi%type default null,
		p_msgtaxichesodd  number default null,
		p_idsess          in sessionidipendenti.idsessione%type default null
	);

	procedure modificaprenotazione (
		p_id_prenotazione   in prenotazioni.idprenotazione%type default null,
		p_dataora           varchar2 default null,
		p_luogopartenza     in prenotazioni.luogopartenza%type default null,
		p_luogoarrivo       in prenotazioni.luogoarrivo%type default null,
		p_npersone          in prenotazioni.npersone%type default null,
		p_nperdis           in prenotazioneaccessibile.npersonedisabili%type default null,
		p_optionals         in varchar2 default null,
		p_convenzionicum    in varchar2 default null,
		p_convenzioninoncum in varchar2 default null,
		p_msgmodifica       number default null,
		p_idsess            in sessioniclienti.idsessione%type default null
	);

	procedure statcorsepnp (
		p_idsess     in sessionidipendenti.idsessione%type default null,
		p_datainizio varchar2 default null,
		p_datafine   varchar2 default null
	);


	type r_prencategoria is record (
			r_idprenotazione prenotazioni.idprenotazione%type,
			r_dataora        prenotazioni.dataora%type,
			r_luogopartenza  prenotazioni.luogopartenza%type,
			r_npersone       prenotazioni.npersone%type,
			r_luogoarrivo    prenotazioni.luogoarrivo%type,
			r_stato          prenotazioni.stato%type,
			r_modificata     prenotazioni.modificata%type,
			r_durata         prenotazioni.durata%type,
			r_prenstd        prenotazionestandard.fk_prenotazione%type,
			r_taxistd        prenotazionestandard.fk_taxi%type,
			r_prenacc        prenotazioneaccessibile.fk_prenotazione%type,
			r_taxiacc        prenotazioneaccessibile.fk_taxiaccessibile%type,
			r_nperdis        prenotazioneaccessibile.npersonedisabili%type,
			r_prenlss        prenotazionelusso.fk_prenotazione%type,
			r_taxilss        prenotazionelusso.fk_taxi%type
	);
	type r_taxicategoria is record (
			r_idtaxi      taxi.idtaxi%type,
			r_npertaxi    taxi.nposti%type,
			r_tariffa     taxi.tariffa%type,
			r_nperdistaxi prenotazioneaccessibile.npersonedisabili%type
	);


---------------------------------Baffa-----------------------------------------

	procedure visualizzaprenotazioni (
		p_idsess          in sessioniclienti.idsessione%type default null,
		p_id_prenotazione in prenotazioni.idprenotazione%type default null,
		p_data            varchar2 default null,
		p_ora             varchar2 default null,
		p_partenza        in prenotazioni.luogopartenza%type default null,
		p_persone         in prenotazioni.npersone%type default null,
		p_arrivo          in prenotazioni.luogoarrivo%type default null,
		p_stato           in prenotazioni.stato%type default null,
		p_durata          in prenotazioni.durata%type default null,
		p_modificata      in prenotazioni.modificata%type default null,
		p_sub             in varchar2 default null,
		p_id_annullata    in prenotazioni.idprenotazione%type default null,
		p_tipotaxi        in varchar2 default null
	);
	procedure visualizzaprenotazionitaxi (
		p_idsess          sessioniclienti.idsessione%type default null,
		p_id_taxi         in taxi.idtaxi%type default null,
		p_id_prenotazione in prenotazioni.idprenotazione%type default null,
		p_data            varchar2 default null,
		p_ora             varchar2 default null,
		p_partenza        in prenotazioni.luogopartenza%type default null,
		p_persone         in prenotazioni.npersone%type default null,
		p_arrivo          in prenotazioni.luogoarrivo%type default null,
		p_stato           in prenotazioni.stato%type default null,
		p_durata          in prenotazioni.durata%type default null,
		p_modificata      in prenotazioni.modificata%type default null,
		p_sub             in varchar2 default null,
		p_id_annullata    in prenotazioni.idprenotazione%type default null
	);
	procedure gestirecorsaprenotata (
		p_idsess          in sessioniclienti.idsessione%type default null,
		p_id_prenotazione in prenotazioni.idprenotazione%type default null,
		p_data            varchar2 default null,
		p_orapartenza     varchar2 default null,
		p_partenza        in prenotazioni.luogopartenza%type default null,
		p_persone         in prenotazioni.npersone%type default null,
		p_arrivo          in prenotazioni.luogoarrivo%type default null,
		p_stato           in prenotazioni.stato%type default null,
		p_oraarrivo       in varchar2 default null,
		p_importo         in corseprenotate.importo%type default null,
		p_km              in corseprenotate.km%type default null,
		p_sub             in varchar2 default null
	);

	procedure statsprenotazioni (
		p_idsess     in sessioniclienti.idsessione%type default null,
		p_datainizio varchar2 default null,
		p_datafine   varchar2 default null,
		p_partenza   in prenotazioni.luogopartenza%type default null,
		p_persone    in prenotazioni.npersone%type default null,
		p_arrivo     in prenotazioni.luogoarrivo%type default null,
		p_stato      in prenotazioni.stato%type default null,
		p_durata     in prenotazioni.durata%type default null,
		p_modificata in prenotazioni.modificata%type default null,
		p_categoria  in varchar2 default null,
		p_tipologia  in varchar2 default null,
		p_sub        in varchar2 default null
	);

	procedure statscorseprenotate (
		p_idsess     in sessioniclienti.idsessione%type default null,
		p_datainizio varchar2 default null,
		p_datafine   varchar2 default null,
		p_partenza   in prenotazioni.luogopartenza%type default null,
		p_persone    in prenotazioni.npersone%type default null,
		p_arrivo     in prenotazioni.luogoarrivo%type default null,
		p_durata     in prenotazioni.durata%type default null,
		p_categoria  in varchar2 default null,
		p_tipologia  in varchar2 default null,
		p_sub        in varchar2 default null
	);

	procedure annullapren (
		p_idsess          in sessioniclienti.idsessione%type default null,
		p_id_prenotazione in prenotazioni.idprenotazione%type default null
	);

-----------------------------------Chine-----------------------------------------
	procedure mvp (
		p_idsess     sessionidipendenti.idsessione%type default null,
		p_autista    autisti.fk_dipendente%type default null,
		p_operatore  operatori.fk_dipendente%type default null,
		p_cliente    clienti.idcliente%type default null,
		p_id         in prenotazioni.idprenotazione%type default null,
		p_data_min   varchar2 default null,
		p_data_max   varchar2 default null,
		p_ora_min    varchar2 default null,
		p_ora_max    varchar2 default null,
		p_partenza   in prenotazioni.luogopartenza%type default null,
		p_persone    in prenotazioni.npersone%type default null,
		p_arrivo     in prenotazioni.luogoarrivo%type default null,
		p_stato      in prenotazioni.stato%type default null,
		p_durata     in prenotazioni.durata%type default null,
		p_modificata in prenotazioni.modificata%type default null,
		p_tipo       in nonanonime.tipo%type default null,
		p_categoria  in varchar2 default null
	);

	procedure avviacorsa (
		p_idsess       sessionidipendenti.idsessione%type default null,
		p_prenotazione prenotazioni.idprenotazione%type default null,
		p_passeggeri   corseprenotate.passeggeri%type default null
	);

	procedure luoghiPopolari(
        p_idSess SESSIONIDIPENDENTI.IDSESSIONE%TYPE default null
    );
end gruppo1;