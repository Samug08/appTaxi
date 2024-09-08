create or replace package Utility AS
    procedure dropDownInformation(datas in gui.StringArray, title in varchar);
    function stringToArray(string in varchar2, delimiter in varchar2 default ';') return gui.StringArray;
    function checkNotPrenotazioniSovrapposte (
        p_inizioPrenotazione date,
        p_finePrenotazione date,
        p_idTaxi in Taxi.IDTaxi%TYPE
    ) RETURN boolean;
      function esiste (
        p_array gui.StringArray,
        p_element varchar2
    ) return boolean;

    function taxiPossiedeOptionals(
        p_id_taxi in Taxi.IDTaxi%TYPE,
        p_IDoptionals gui.StringArray
    )
    return boolean;

    function esisteTaxiPossiedeOptionals (
        p_IDoptionals gui.StringArray
    ) return boolean;

    procedure setTaxiNull(
        p_id_prenotazione in PRENOTAZIONI.IDPRENOTAZIONE%TYPE
    );

end Utility;