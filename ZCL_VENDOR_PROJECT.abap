class ZCL_VENDOR_PROJECT definition
  public
  final
  create public .

public section.

  class-methods GET_VENDOR
    importing
      !IP_LIFNR type LIFNR
    exporting
      !EP_LAND1 type LAND1
      !EP_NAME1 type LFA1-NAME1
      !EP_ORT01 type LFA1-ORT01 .
  class-methods GET_PO
    importing
      !IP_LIFNR type LIFNR
      !IP_EBELN type EBELN
    exporting
      !EP_EKKO type ZTT_EKKO .
  class-methods GET_PO_ITEMS
    importing
      !IP_EBELN type EBELN
    exporting
      !EP_EKPO type ZTT_EKPO16 .
  class-methods GET_PO_BAPI
    importing
      !IP_EBELN type EBELN
    exporting
      !EP_PO_HEADER type BAPIEKKOL
      !EP_PO_ITEMS type ZTT_BAPI_PO_ITEMS .
protected section.
private section.
ENDCLASS.



CLASS ZCL_VENDOR_PROJECT IMPLEMENTATION.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Static Public Method ZCL_VENDOR_PROJECT=>GET_PO
* +-------------------------------------------------------------------------------------------------+
* | [--->] IP_LIFNR                       TYPE        LIFNR
* | [--->] IP_EBELN                       TYPE        EBELN
* | [<---] EP_EKKO                        TYPE        ZTT_EKKO
* +--------------------------------------------------------------------------------------</SIGNATURE>
  method GET_PO.
    select ebeln,
      lifnr,
      bukrs,
      bsart,
      aedat
      INTO CORRESPONDING FIELDS OF table @ep_ekko
      from ekko
      where lifnr = @ip_lifnr and ( ebeln = @ip_ebeln  ).
  endmethod.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Static Public Method ZCL_VENDOR_PROJECT=>GET_PO_BAPI
* +-------------------------------------------------------------------------------------------------+
* | [--->] IP_EBELN                       TYPE        EBELN
* | [<---] EP_PO_HEADER                   TYPE        BAPIEKKOL
* | [<---] EP_PO_ITEMS                    TYPE        ZTT_BAPI_PO_ITEMS
* +--------------------------------------------------------------------------------------</SIGNATURE>
  method GET_PO_BAPI.
    call FUNCTION 'BAPI_PO_GETDETAIL'
    exporting
      purchaseorder = ip_ebeln
      IMPORTING
        po_header = ep_po_header
        tables
          po_items = ep_po_items.
  endmethod.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Static Public Method ZCL_VENDOR_PROJECT=>GET_PO_ITEMS
* +-------------------------------------------------------------------------------------------------+
* | [--->] IP_EBELN                       TYPE        EBELN
* | [<---] EP_EKPO                        TYPE        ZTT_EKPO16
* +--------------------------------------------------------------------------------------</SIGNATURE>
  method GET_PO_ITEMS.
    select ebeln
      ebelp
      matnr
      menge
      netpr
      werks
      into CORRESPONDING FIELDS OF table ep_ekpo
      from ekpo
      where ebeln = ip_ebeln.
  endmethod.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Static Public Method ZCL_VENDOR_PROJECT=>GET_VENDOR
* +-------------------------------------------------------------------------------------------------+
* | [--->] IP_LIFNR                       TYPE        LIFNR
* | [<---] EP_LAND1                       TYPE        LAND1
* | [<---] EP_NAME1                       TYPE        LFA1-NAME1
* | [<---] EP_ORT01                       TYPE        LFA1-ORT01
* +--------------------------------------------------------------------------------------</SIGNATURE>
  method GET_VENDOR.
    select single land1
                  name1
                  ort01
      into (ep_land1, ep_name1, ep_ort01)
      from lfa1 where lifnr = ip_lifnr.
  endmethod.
ENDCLASS.