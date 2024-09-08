create or replace package BODY Utility AS
  procedure dropDownInformation(datas in gui.StringArray, title in varchar) is
      begin
        htp.prn('<td>');
        gui.apriDiv(classe => 'multiSelect');
				gui.apriDiv(classe => 'multiSelectBtn', onclick => 'apriMultiSelect(this.parentNode)');
					htp.prn('<span class="text">'|| title ||'</span>');
					htp.prn('<span class="arrow"></span>');
				htp.prn('</div>');
				gui.apriDiv(ident => 'multiSelect-content', classe => 'multiSelect-content');

				for i in 1..datas.count loop
					gui.apriDiv(ident => 'option');
					htp.prn('<label for="'|| datas(i)||'">'|| datas(i) ||'</label>');
					gui.chiudiDiv();
				end loop;
				gui.chiudiDiv();
			gui.chiudiDiv();
        htp.prn('</td>');
    end dropDownInformation;
  function stringToArray(string in varchar2, delimiter in varchar2 default ';')
        return gui.StringArray
        is outputArray gui.StringArray:=gui.StringArray();
        begin
            for x in (
                WITH rws AS (
                         SELECT string FROM dual
                    )
                    SELECT regexp_substr(
                   string,
                   '[^'||delimiter||']+',
                   1,
                   LEVEL
               ) value
                    FROM rws
                    CONNECT BY LEVEL <= LENGTH(string) - LENGTH(REPLACE(string, delimiter)) + 1
                ) loop
                    outputArray.extend;
                    outputArray(outputArray.COUNT):=x.value;
                    end loop;
            RETURN outputArray;
        end stringToArray;
  function checkNotPrenotazioniSovrapposte (
        p_inizioPrenotazione date,
        p_finePrenotazione date,
        p_idTaxi in Taxi.IDTaxi%TYPE
    )
    RETURN boolean
    is
        v_soddisfa boolean;
    begin
        v_soddisfa:=true;
        for y in (
            select *
            from Turni Tu, Prenotazioni P
            left join PrenotazioneStandard PrenS on P.IDprenotazione=PrenS.FK_Prenotazione
            left join PrenotazioneAccessibile PrenA on P.IDprenotazione=PrenA.FK_Prenotazione
            left join PrenotazioneLusso PrenL on P.IDprenotazione=PrenL.FK_Prenotazione
            where
            Tu.FK_Taxi=p_idTaxi AND
            (Tu.FK_Taxi=PrenS.FK_Taxi OR Tu.FK_Taxi=PrenA.FK_TaxiAccessibile OR Tu.FK_Taxi=PrenL.FK_Taxi) AND
            P.DataOra >= Tu.DataOraInizio AND
            P.DataOra <= Tu.DataOraFine AND
            P.Stato='accettata'
        ) loop
            if (not(p_inizioPrenotazione >= y.DataOra + y.Durata/(24*60) OR p_finePrenotazione <=y.DataOra))
                --i due intervalli si intersecano
            then v_soddisfa:=false;
            end if;
        end loop;

        return v_soddisfa;
    end checkNotPrenotazioniSovrapposte;
    function esiste (
        p_array gui.StringArray,
        p_element varchar2
    ) return boolean
    is
    begin
        if p_array.count=0 then return false; end if;
        if p_array.count is null then return false; end if;
        for i in 1..p_array.count
        loop
            if p_array(i)=p_element
            then return true;
            end if;
        end loop;
        return false;
    end esiste;

    --scoppia tutto se c'è un valore null nell'array :)
    function taxiPossiedeOptionals(
        p_id_taxi in Taxi.IDTaxi%TYPE,
        p_IDoptionals gui.StringArray
    )
    return boolean
    is
        v_IDoptionalsTaxi gui.StringArray:=gui.StringArray();
        v_soddisfa boolean;
    begin

        if p_IDoptionals.count=0 then return true; end if;

        --prendo tutti gli optional offerti da quel taxi
        for x in(
            select O.IDoptionals
            from Optionals O
            join PossiedeTaxiLusso PTL on O.IDoptionals=PTL.FK_optionals
            and PTL.FK_TaxiLusso=p_id_taxi
        ) loop
            v_IDoptionalsTaxi.extend();
            v_IDoptionalsTaxi(v_IDoptionalsTaxi.count):=x.IDoptionals;
        end loop;

        if v_IDoptionalsTaxi.count=0 then return false; end if;

        v_soddisfa:=true;
        for i in 1..p_IDoptionals.count loop
            if not esiste(v_IDoptionalsTaxi, p_IDoptionals(i))
            then
                v_soddisfa:=false;
            end if;
        end loop;

        return v_soddisfa;
    end taxiPossiedeOptionals;

    function esisteTaxiPossiedeOptionals (
        p_IDoptionals gui.StringArray
    ) return boolean
    is
    begin

        if p_IDoptionals.count=0 then return true; end if;

        for x in ( --devo mettere il when no date found
            select FK_taxi
            from taxiLusso
        ) loop
            if taxiPossiedeOptionals(x.FK_taxi, p_IDoptionals)
            then
                return true;
            end if;
        end loop;

        return false;

    end esisteTaxiPossiedeOptionals;
    procedure setTaxiNull(
        p_id_prenotazione in PRENOTAZIONI.IDPRENOTAZIONE%TYPE
    ) is
    begin
        savepoint savepointTaxiNull;
        update prenotazioneStandard set fk_taxi=null where fk_prenotazione=p_id_prenotazione;
        update prenotazioneAccessibile set fk_taxiAccessibile=null where fk_prenotazione=p_id_prenotazione;
        update prenotazioneLusso set fk_taxi=null where fk_prenotazione=p_id_prenotazione;
        commit;
        EXCEPTION
        when others
        then  rollback to savepointTaxiNull; raise;
        return;
    end setTaxiNull;
end Utility;