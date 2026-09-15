*&---------------------------------------------------------------------*
*& Report ZVENDORPROJECT_DISPLAY
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*

REPORT zvendorproject_display.
TYPE-POOLS: slis.
PARAMETERS p_lifnr TYPE lifnr.
PARAMETERS p_ebeln TYPE ebeln.
SELECT-OPTIONS s_aedat FOR sy-datum.
DATA: wa_lfa1 TYPE lfa1.
DATA: wa_zvendorproject TYPE zvendorproject.
DATA: it_zvendorproject TYPE TABLE OF zvendorproject.
DATA: it_ekko TYPE TABLE OF ekko,
      wa_ekko TYPE ekko.
DATA: it_ekpo TYPE TABLE OF ekpo,
      wa_ekpo TYPE ekpo.
DATA: it_ekko_po TYPE TABLE OF ekpo.
DATA: lv_item_count TYPE i.
DATA: wa_makt TYPE makt.
DATA: it_fieldcat TYPE slis_t_fieldcat_alv.
DATA: wa_fieldcat TYPE slis_fieldcat_alv.
data: it_sort type slis_t_sortinfo_alv.
data: wa_sort type slis_sortinfo_alv.

"Get vendor details from lfa1
*SELECT SINGLE land1
*              name1
*              ort01
*  INTO CORRESPONDING FIELDS OF wa_lfa1
*  FROM lfa1
*  WHERE lifnr = p_lifnr .

CALL METHOD zcl_vendor_project=>get_vendor
  EXPORTING
    ip_lifnr = p_lifnr
  IMPORTING
    ep_land1 = wa_lfa1-land1
    ep_name1 = wa_lfa1-name1
    ep_ort01 = wa_lfa1-ort01.

IF sy-subrc <> 0.
  WRITE:/ 'Vendor does not exist'.
  EXIT.
ENDIF.

IF sy-subrc = 0.
  MOVE-CORRESPONDING wa_lfa1 TO wa_zvendorproject. "values from wa_lfa1 are copied to wa_zvendorproject with same names
  "MODIFY zvendorproject FROM wa_zvendorproject. "writes the contents to the database table.

  WRITE:/ 'Vendor Number :', p_lifnr,
        / 'Country:', wa_lfa1-land1,
        / 'Name:', wa_lfa1-name1,
        / 'City:', wa_lfa1-ort01.
  ULINE.

  "Get purchase order  from ekko
*  SELECT ebeln,
*    lifnr,
*    bukrs,
*    bsart,
*    aedat
*    INTO CORRESPONDING FIELDS OF TABLE @it_ekko
*    FROM ekko WHERE lifnr = @p_lifnr  and ( ebeln = @p_ebeln  ) and aedat in @s_aedat.
  CALL METHOD zcl_vendor_project=>get_po
    EXPORTING
      ip_lifnr = p_lifnr
      ip_ebeln = p_ebeln
    IMPORTING
      ep_ekko  = it_ekko.
  DELETE it_ekko WHERE aedat NOT IN s_aedat.
*    IF sy-subrc <> 0.
*  WRITE:/ 'No purchase orders found for this vendor.' .
*  EXIT.
*ENDIF.
  IF it_ekko IS INITIAL.
    MESSAGE 'NO PURCHASE ORDER FOUND for this vendor' TYPE 'I'.
    EXIT.
  ENDIF.

  DESCRIBE TABLE it_ekko LINES DATA(lv_count).
  WRITE:/ 'Total Purchase orders:', lv_count.
  ULINE.

  LOOP AT it_ekko INTO wa_ekko.
    WRITE:/ 'Purchase Order', wa_ekko-ebeln,
    / 'Vendor:' ,wa_ekko-lifnr,
    / 'Company code:', wa_ekko-bukrs,
    / 'Document type:', wa_ekko-bsart,
    /'Created on: ', wa_ekko-aedat.
    ULINE.
  ENDLOOP.

  "Get PO items from ekpo
*  SELECT ebeln
*    ebelp
*    matnr
*    menge
*    netpr
*    werks
*    INTO CORRESPONDING FIELDS OF TABLE it_ekpo
*    FROM ekpo
*    FOR ALL ENTRIES IN it_ekko
*    WHERE ebeln = it_ekko-ebeln.

*  IF sy-subrc <> 0.
*    WRITE:/ 'No items found for Purchase order', wa_ekko-ebeln.
*    EXIT.
*  ENDIF.

loop at it_ekko into wa_ekko.
  clear it_ekko_po.
  call method zcl_vendor_project=>get_po_items
  exporting
    ip_ebeln = wa_ekko-ebeln
    IMPORTING
      ep_ekpo = it_ekko_po.

  append lines of it_ekko_po to it_ekpo.
  ENDLOOP.

  DESCRIBE TABLE it_ekpo LINES lv_item_count.
  WRITE:/ 'Total PO items:', lv_item_count.

  WRITE:/ 'PURCHASE ORDER ITEM DETAILS',
       / '----------------------------'.
  SORT it_ekpo BY ebeln ebelp.
  LOOP AT it_ekpo INTO wa_ekpo.
    "Get material description from MAKT
    SELECT SINGLE maktx
      INTO wa_makt-maktx
      FROM makt
      WHERE matnr = wa_ekpo-matnr
      AND spras = sy-langu. "get material description where language is same as my sap logon.
    MOVE-CORRESPONDING wa_ekpo TO wa_zvendorproject.
    wa_zvendorproject-maktx = wa_makt-maktx.
    APPEND wa_zvendorproject TO it_zvendorproject.
    MODIFY zvendorproject FROM wa_zvendorproject.

    .

*  WRITE:/ 'PO:', wa_ekpo-ebeln,
*  /'Item:', wa_ekpo-ebelp,
*  /'Material:', wa_ekpo-matnr,
*  /'Material Description:', wa_makt-maktx,
*  /'Quantity:', wa_ekpo-menge,
*  /'Net price:', wa_ekpo-netpr,
*  /'Plant:', wa_ekpo-werks.


    ULINE.
  ENDLOOP.
  DESCRIBE TABLE it_ekpo lines lv_item_count.
  MESSAGE |{ lv_item_count } Purchase order items retrieved successfully | type 'S'.
ENDIF.

CLEAR wa_fieldcat.
wa_fieldcat-fieldname ='LIFNR'.
wa_fieldcat-seltext_m = 'Supplier'.
APPEND wa_fieldcat TO it_fieldcat.

CLEAR wa_fieldcat.
wa_fieldcat-fieldname ='NAME1'.
wa_fieldcat-seltext_m = 'Vendor name'.
APPEND wa_fieldcat TO it_fieldcat.

CLEAR wa_fieldcat.
wa_fieldcat-fieldname ='LAND1'.
wa_fieldcat-seltext_m = 'Country'.
APPEND wa_fieldcat TO it_fieldcat.



CLEAR wa_fieldcat.
wa_fieldcat-fieldname ='ort01'.
wa_fieldcat-seltext_m = 'City'.
APPEND wa_fieldcat TO it_fieldcat.


CLEAR wa_fieldcat.
wa_fieldcat-fieldname ='EBELN'.
wa_fieldcat-seltext_m = 'Purchase order'.
APPEND wa_fieldcat TO it_fieldcat.

CLEAR wa_fieldcat.
wa_fieldcat-fieldname ='EBELP'.
wa_fieldcat-seltext_m = 'ITEM'.
APPEND wa_fieldcat TO it_fieldcat.

CLEAR wa_fieldcat.
wa_fieldcat-fieldname ='matnr'.
wa_fieldcat-seltext_m = 'Material'.
APPEND wa_fieldcat TO it_fieldcat.



CLEAR wa_fieldcat.
wa_fieldcat-fieldname ='maktx'.
wa_fieldcat-seltext_m = 'Material description'.
APPEND wa_fieldcat TO it_fieldcat.

CLEAR wa_fieldcat.
wa_fieldcat-fieldname ='menge'.
wa_fieldcat-seltext_m = 'Quantity'.
APPEND wa_fieldcat TO it_fieldcat.

CLEAR wa_fieldcat.
wa_fieldcat-fieldname ='netpr'.
wa_fieldcat-seltext_m = 'Net price'.
APPEND wa_fieldcat TO it_fieldcat.

CLEAR wa_fieldcat.
wa_fieldcat-fieldname ='werks'.
wa_fieldcat-seltext_m = 'Plant'.
APPEND wa_fieldcat TO it_fieldcat.

MESSAGE |{ lv_count }'Purchase Order data retrieved successfully'.| TYPE 'S'.

clear wa_sort.
wa_sort-fieldname = 'EBELN'.
wa_sort-up = 'X'.
append wa_sort to it_sort.

clear wa_sort.
wa_sort-fieldname = 'EBELP'.
wa_sort-up = 'X'.
append wa_sort to it_sort.

"display po data in ALV
CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
  EXPORTING
    "i_structure_name = 'zvendorproject'
    it_fieldcat = it_fieldcat
    it_sort = it_sort
  TABLES
    t_outtab    = it_zvendorproject.