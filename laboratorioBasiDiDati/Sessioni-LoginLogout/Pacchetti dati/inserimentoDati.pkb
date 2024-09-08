--SET DEFINE OFF;

create or replace PACKAGE BODY inserimentoDati as

procedure inizioTurni(
    idSess in SESSIONIDIPENDENTI.IDSESSIONE%TYPE,
    modifica in varchar2 default null
) is

        head gui.StringArray;

        BEGIN

    --QUESTO SERVE PER QUANDO SI REFRESHA LA PAGINA, IN MODO DA NON FAR RESTARE IL POP UP DELLA MODIFICA AVVENUTA CON SUCCESSO
     htp.prn('<script>   const newUrl = "'||U_ROOT||'.inizioTurni?idSess='||idSess||'";
                        history.replaceState(null, null, newUrl);
        </script>');


        head := gui.StringArray ('Manager', 'Autista', 'Taxi', 'Data Ora Inizio', 'Data Ora Fine', 'Data Ora Inizio Effettivo', 'Data Ora Fine Effettivo');
        gui.apriPagina(titolo => 'inizioTurni', idSessione=> idSess);
        gui.AGGIUNGIINTESTAZIONE('Inizio Turni');

        /* Controllo che l'utente abbia i permessi necessari */
        IF(sessionhandler.getRuolo(idSess) = 'Manager') THEN
            IF(modifica IS NOT NULL AND modifica = 'true') THEN
                UPDATE TURNI t
                SET t.DATAORAINIZIOEFF = SYSDATE
                WHERE trunc(t.DATAORAINIZIO, 'hh') <= trunc(SYSDATE, 'hh')
                    AND t.DATAORAINIZIO < SYSDATE
                    AND SYSDATE < t.DATAORAFINE
                    AND t.DATAORAINIZIOEFF IS NULL
                    AND t.DATAORAFINEEFF IS NULL;

                gui.APRITABELLA (elementi => head);
                    FOR turno IN (
                        SELECT *
                        FROM TURNI t
                        WHERE  trunc(t.DATAORAINIZIO, 'hh') <= trunc(SYSDATE, 'hh')
                            AND t.DATAORAINIZIO < SYSDATE
                            AND SYSDATE< t.DATAORAFINE
                            AND t.DATAORAINIZIOEFF IS NOT NULL
                            AND t.DATAORAFINEEFF IS NULL
                    )
                    LOOP
                    gui.AGGIUNGIRIGATABELLA;
                        gui.AGGIUNGIELEMENTOTABELLA(elemento => turno.FK_MANAGER);
                        gui.AGGIUNGIELEMENTOTABELLA(elemento => turno.FK_AUTISTA);
                        gui.AGGIUNGIELEMENTOTABELLA(elemento => turno.FK_TAXI);
                        gui.AGGIUNGIELEMENTOTABELLA(elemento => TO_CHAR(turno.DATAORAINIZIO, 'yyyy-mm-dd hh24:mi:ss'));
                        gui.AGGIUNGIELEMENTOTABELLA(elemento => TO_CHAR(turno.DATAORAFINE, 'yyyy-mm-dd hh24:mi:ss'));
                        gui.AGGIUNGIELEMENTOTABELLA(elemento => TO_CHAR(turno.DATAORAINIZIOEFF, 'yyyy-mm-dd hh24:mi:ss'));
                        gui.AGGIUNGIELEMENTOTABELLA(elemento => TO_CHAR(turno.DATAORAFINEEFF, 'yyyy-mm-dd hh24:mi:ss'));
                    gui.CHIUDIRIGATABELLA;
                    END LOOP;
                    gui.ChiudiTabella;
            ELSE
                gui.APRITABELLA (elementi => head);
                    FOR turno IN (
                        SELECT *
                        FROM TURNI t
                        WHERE  trunc(t.DATAORAINIZIO, 'hh') <= trunc(SYSDATE, 'hh')
                            AND t.DATAORAINIZIO < SYSDATE
                            AND SYSDATE< t.DATAORAFINE
                            AND t.DATAORAINIZIOEFF IS NULL
                    )
                    LOOP
                    gui.AGGIUNGIRIGATABELLA;
                        gui.AGGIUNGIELEMENTOTABELLA(elemento => turno.FK_MANAGER);
                        gui.AGGIUNGIELEMENTOTABELLA(elemento => turno.FK_AUTISTA);
                        gui.AGGIUNGIELEMENTOTABELLA(elemento => turno.FK_TAXI);
                        gui.AGGIUNGIELEMENTOTABELLA(elemento => TO_CHAR(turno.DATAORAINIZIO, 'yyyy-mm-dd hh24:mi:ss'));
                        gui.AGGIUNGIELEMENTOTABELLA(elemento => TO_CHAR(turno.DATAORAFINE, 'yyyy-mm-dd hh24:mi:ss'));
                        gui.AGGIUNGIELEMENTOTABELLA(elemento => TO_CHAR(turno.DATAORAINIZIOEFF, 'yyyy-mm-dd hh24:mi:ss'));
                        gui.AGGIUNGIELEMENTOTABELLA(elemento => TO_CHAR(turno.DATAORAFINEEFF, 'yyyy-mm-dd hh24:mi:ss'));
                    gui.CHIUDIRIGATABELLA;
                END LOOP;
                gui.ChiudiTabella;
            END IF;


        ELSE
            gui.AGGIUNGIPOPUP(FALSE, 'Errore: non hai i permessi necessari per accedere a questa pagina!', costanti.URL||'gui.homepage?idsessione'||idSess);
    END IF;
    IF(modifica IS NULL) THEN
        gui.BOTTONEAGGIUNGI(testo=>'Inizia Turni', classe=>'bottone2', url=> U_ROOT||'.inizioTurni?idSess='||idSess||'&modifica=true');
    END IF;

    gui.CHIUDIPAGINA();

END inizioTurni;


procedure fineTurni(
    idSess in SESSIONIDIPENDENTI.IDSESSIONE%TYPE,
    modifica in varchar2 default null
) is

        head gui.StringArray;

        BEGIN

    --QUESTO SERVE PER QUANDO SI REFRESHA LA PAGINA, IN MODO DA NON FAR RESTARE IL POP UP DELLA MODIFICA AVVENUTA CON SUCCESSO
     htp.prn('<script>   const newUrl = "'||U_ROOT||'.fineTurni?idSess='||idSess||'";
                        history.replaceState(null, null, newUrl);
        </script>');


        head := gui.StringArray ('Manager', 'Autista', 'Taxi', 'Data Ora Inizio', 'Data Ora Fine', 'Data Ora Inizio Effettivo', 'Data Ora Fine Effettivo');
        gui.apriPagina(titolo => 'fineTurni', idSessione=> idSess);
        gui.AGGIUNGIINTESTAZIONE('Finisci Turni');

        -- Controllo che l'utente abbia i permessi necessari
        IF(sessionhandler.getRuolo(idSess) = 'Manager') THEN
            -- Modifica + visualizzazione della modifica
            IF(modifica IS NOT NULL AND modifica = 'true') THEN
                UPDATE TURNI t
                SET t.DATAORAFINEEFF = SYSDATE
                WHERE trunc(t.DATAORAINIZIO, 'dd') = trunc(SYSDATE, 'dd')
                    AND (SELECT MAX(t2.DATAORAFINE)
                            FROM TURNI t2
                            WHERE  trunc(t2.DATAORAINIZIO, 'dd') = trunc(SYSDATE, 'dd')
                                AND t2.DATAORAFINE < SYSDATE) = t.DATAORAFINE
                    AND t.DATAORAINIZIOEFF IS NOT NULL
                    AND t.DATAORAFINEEFF IS NULL;

                gui.APRITABELLA (elementi => head);
                FOR turno IN (
                    SELECT *
                    FROM TURNI t
                    WHERE trunc(t.DATAORAINIZIO, 'dd') = trunc(SYSDATE, 'dd')
                        AND (SELECT MAX(t2.DATAORAFINE)
                                FROM TURNI t2
                                WHERE  trunc(t2.DATAORAINIZIO, 'dd') = trunc(SYSDATE, 'dd')
                                    AND t2.DATAORAFINE < SYSDATE) = t.DATAORAFINE
                        AND t.DATAORAINIZIOEFF IS NOT NULL
                        AND t.DATAORAFINEEFF IS NOT NULL
                )
                LOOP
                gui.AGGIUNGIRIGATABELLA;
                    gui.AGGIUNGIELEMENTOTABELLA(elemento => turno.FK_MANAGER);
                    gui.AGGIUNGIELEMENTOTABELLA(elemento => turno.FK_AUTISTA);
                    gui.AGGIUNGIELEMENTOTABELLA(elemento => turno.FK_TAXI);
                    gui.AGGIUNGIELEMENTOTABELLA(elemento => TO_CHAR(turno.DATAORAINIZIO, 'yyyy-mm-dd hh24:mi:ss'));
                    gui.AGGIUNGIELEMENTOTABELLA(elemento => TO_CHAR(turno.DATAORAFINE, 'yyyy-mm-dd hh24:mi:ss'));
                    gui.AGGIUNGIELEMENTOTABELLA(elemento => TO_CHAR(turno.DATAORAINIZIOEFF, 'yyyy-mm-dd hh24:mi:ss'));
                    gui.AGGIUNGIELEMENTOTABELLA(elemento => TO_CHAR(turno.DATAORAFINEEFF, 'yyyy-mm-dd hh24:mi:ss'));
                gui.CHIUDIRIGATABELLA;
                END LOOP;
                gui.ChiudiTabella;
            -- visualizzazione dei turni da poter terminare
            ELSE
                gui.APRITABELLA (elementi => head);

                FOR turno IN (
                    SELECT *
                    FROM TURNI t
                    WHERE trunc(t.DATAORAINIZIO, 'dd') = trunc(SYSDATE, 'dd')
                        AND (SELECT MAX(t2.DATAORAFINE)
                                FROM TURNI t2
                                WHERE  trunc(t2.DATAORAINIZIO, 'dd') = trunc(SYSDATE, 'dd')
                                    AND t2.DATAORAFINE < SYSDATE) = t.DATAORAFINE
                        AND t.DATAORAINIZIOEFF IS NOT NULL
                        AND t.DATAORAFINEEFF IS NULL
                )
                LOOP
                gui.AGGIUNGIRIGATABELLA;
                    gui.AGGIUNGIELEMENTOTABELLA(elemento => turno.FK_MANAGER);
                    gui.AGGIUNGIELEMENTOTABELLA(elemento => turno.FK_AUTISTA);
                    gui.AGGIUNGIELEMENTOTABELLA(elemento => turno.FK_TAXI);
                    gui.AGGIUNGIELEMENTOTABELLA(elemento => TO_CHAR(turno.DATAORAINIZIO, 'yyyy-mm-dd hh24:mi:ss'));
                    gui.AGGIUNGIELEMENTOTABELLA(elemento => TO_CHAR(turno.DATAORAFINE, 'yyyy-mm-dd hh24:mi:ss'));
                    gui.AGGIUNGIELEMENTOTABELLA(elemento => TO_CHAR(turno.DATAORAINIZIOEFF, 'yyyy-mm-dd hh24:mi:ss'));
                    gui.AGGIUNGIELEMENTOTABELLA(elemento => TO_CHAR(turno.DATAORAFINEEFF, 'yyyy-mm-dd hh24:mi:ss'));
                gui.CHIUDIRIGATABELLA;
                END LOOP;
                gui.ChiudiTabella;
            END IF;
        ELSE
            gui.AGGIUNGIPOPUP(FALSE, 'Errore: non hai i permessi necessari per accedere a questa pagina!', costanti.URL||'gui.homepage?idsessione'||idSess);
    END IF;
    IF(modifica IS NULL) THEN
        gui.BOTTONEAGGIUNGI(testo=>'Fine Turni', classe=>'bottone2', url=> U_ROOT||'.fineTurni?idSess='||idSess||'&modifica=true');
    END IF;

    gui.CHIUDIPAGINA();

END fineTurni;

END inserimentoDati;
