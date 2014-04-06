{
    fpGUI  -  Free Pascal GUI Toolkit

    Copyright (C) 2006 - 2010 See the file AUTHORS.txt, included in this
    distribution, for details of the copyright.

    See the file COPYING.modifiedLGPL, included in this distribution,
    for details about redistributing fpGUI.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

    Description:
      Defines a ComboBox control. Also known as a Choice List control.
}

unit lp_combobox;

{$mode objfpc}{$H+}

{.$Define DEBUG}

{ TODO: When combobox Items changes, the combobox needs to refresh. We need a
      custom StringItems class to notify us of changes. See TpgfListBox for
      an example. }
      
{ TODO: Implement .BeginUpdate and .EndUpdate methods so we know when to refresh
      the items list. }

{ TODO: Introduce SideMargin and HeightMargin like TpgfEdit, instead of just
      the single Margin property. }

{
This is an example of what we can aim for:
You need a mono font to see the correct layout.


               TpgfBaseComboBox
              _________|______________
             |                        |
   TpgfBaseStaticCombo        TpgfBaseEditCombo
       ______|_________               |
      |                |         TpgfEditCombo
      |                |
 TpgfComboBox   TpgfBaseColorCombo
                       |
                 TpgfColorComboBox
}

interface

uses
  Classes,
  SysUtils,
  lp_defs,
  lp_main,
  lp_widget,
  lp_popupwindow;

type
  // widget options
  TpgfComboOption = (wo_FocusItemTriggersOnChange, wo_AllowUserBlank);
  TpgfComboOptions = set of TpgfComboOption;


  TpgfBaseComboBox = class(TpgfWidget)
  private
    FDropDownCount: integer;
    FFont: TpgfFont;
    FOnChange: TNotifyEvent;
    FOnCloseUp: TNotifyEvent;
    FOnDropDown: TNotifyEvent;
    FOptions: TpgfComboOptions;
    FExtraHint: string;
    FReadOnly: Boolean;
    function    GetFontDesc: string;
    procedure   SetDropDownCount(const AValue: integer);
    procedure   SetFocusItem(const AValue: integer);
    procedure   SetFontDesc(const AValue: string);
    procedure   SetExtraHint(const AValue: string);
    procedure   SetReadOnly(const AValue: Boolean);
  protected
    FAutoSize: Boolean;
    FMargin: integer;
    FInternalBtnRect: TpgfRect;
    FFocusItem: integer;
    FItems: TStringList;
    FBtnPressed: Boolean;
    FStoredShowHint: Boolean;
    procedure   DisableShowHint;
    procedure   RestoreShowHint;
    procedure   SetMargin(const AValue: integer); virtual;
    procedure   SetAutoSize(const AValue: Boolean); virtual;
    procedure   CalculateInternalButtonRect; virtual;
    procedure   InternalOnClose(Sender: TObject); virtual;
    procedure   InternalItemsChanged(Sender: TObject); virtual;
    procedure   HandleKeyPress(var keycode: word; var shiftstate: TShiftState; var consumed: boolean); override;
    procedure   DoOnChange; virtual;
    procedure   DoOnDropDown; virtual;
    procedure   DoDropDown; virtual; abstract;
    procedure   DoOnCloseUp; virtual;
    procedure   PaintInternalButton; virtual;
    function    GetDropDownPos(AParent, AComboBox, ADropDown: TpgfWidget): TpgfRect; virtual;
    property    AutoSize: Boolean read FAutoSize write SetAutoSize default False;
    property    DropDownCount: integer read FDropDownCount write SetDropDownCount default 8;
    property    ExtraHint: string read FExtraHint write SetExtraHint;
    property    FocusItem: integer read FFocusItem write SetFocusItem;
    property    FontDesc: string read GetFontDesc write SetFontDesc;
    property    Items: TStringList read FItems;    {$Note Make this read/write }
    property    Options: TpgfComboOptions read FOptions write FOptions;
    property    Margin: integer read FMargin write SetMargin default 1;
    property    ReadOnly: Boolean read FReadOnly write SetReadOnly default False;
    property    OnChange: TNotifyEvent read FOnChange write FOnChange;
    property    OnCloseUp: TNotifyEvent read FOnCloseUp write FOnCloseUp;
    property    OnDropDown: TNotifyEvent read FOnDropDown write FOnDropDown;
  public
    constructor Create(AOwner: TComponent); override;
    destructor  Destroy; override;
    property    Font: TpgfFont read FFont;
  end;
  

  TpgfBaseStaticCombo = class(TpgfBaseComboBox)
  private
    procedure   InternalBtnClick(Sender: TObject);
  protected
    FDropDown: TfpgPopupWindow;
    procedure   DoDropDown; override;
    procedure   DoDrawText(const ARect: TpgfRect); virtual;
    function    GetText: string; virtual;
    function    HasText: boolean; virtual;
    procedure   SetText(const AValue: string); virtual;
    procedure   HandleResize(AWidth, AHeight: TpgfCoord); override;
    procedure   HandleKeyPress(var keycode: word; var shiftstate: TShiftState; var consumed: boolean); override;
    procedure   HandleLMouseDown(x, y: integer; shiftstate: TShiftState); override;
    procedure   HandleLMouseUp(x, y: integer; shiftstate: TShiftState); override;
    procedure   HandleMouseScroll(x, y: integer; shiftstate: TShiftState; delta: smallint); override;
    procedure   HandlePaint; override;
    property    Text: string read GetText write SetText;
  public
    constructor Create(AOwner: TComponent); override;
    destructor  Destroy; override;
    procedure   Update;
  end;


  TpgfComboBox = class(TpgfBaseStaticCombo)
  published
    //property    AcceptDrops;
    property    Align;
    property    AutoSize;
    property    BackgroundColor default clBoxColor;
    property    DropDownCount;
    property    Enabled;
    property    ExtraHint;
    property    FocusItem;
    property    FontDesc;
    property    Height;
    ///property    Hint;
    property    Items;
    property    Margin;
    property    Options;
    ///property    ParentShowHint;
    property    ReadOnly;
    ///property    ShowHint;
    property    TabOrder;
    property    Text;
    property    TextColor;
    property    Width;
    property    OnChange;
    property    OnCloseUp;
    {property    OnDragDrop;
    property    OnDragEnter;
    property    OnDragLeave;
    property    OnDragStartDetected;
    property    OnDropDown;
    property    OnEnter;
    property    OnExit;
    property    OnShowHint; }
  end;
  

function CreateComboBox(AOwner: TComponent; x, y, w: TpgfCoord; AList: TStringList;
      h: TpgfCoord = 0): TpgfComboBox;


implementation

uses
  lp_listbox,
  dbugintf,
  math;
  

type
  { This is the class representing the dropdown window of the combo box. }
  TComboboxDropdownWindow = class(TfpgPopupWindow)
  private
    FCallerWidget: TpgfBaseStaticCombo;
    FListBox: TlpListBox;
    procedure   SetFirstItem;
  protected
    procedure   ListBoxSelect(Sender: TObject);
    procedure   HandleShow; override;
    procedure   HandleKeyPress(var keycode: word; var shiftstate: TShiftState; var consumed: boolean); override;
  public
    constructor Create(AOwner: TComponent; ACallerWidget: TpgfBaseStaticCombo); reintroduce;
    property    ListBox: TlpListBox read FListBox;
  end;


{ TpgfBaseComboBox }

procedure TpgfBaseComboBox.SetDropDownCount(const AValue: integer);
begin
  if FDropDownCount = AValue then
    Exit;
  FDropDownCount := AValue;
end;

function TpgfBaseComboBox.GetFontDesc: string;
begin
  Result := FFont.FontDesc;
end;

{ Focusitem is 0 based like the Delphi ItemIndex property.
  So at startup, FocusItem = -1 which means nothing is selected. If
  FocusItem = 0 it means the first item is selected etc. }
procedure TpgfBaseComboBox.SetFocusItem(const AValue: integer);
begin
  if ReadOnly then
    Exit;
  if FFocusItem = AValue then
    Exit; //==>
  FFocusItem := AValue;

  // do some limit check corrections
  if FFocusItem < -1 then
    FFocusItem := -1   // nothing is selected
  else if FFocusItem > FItems.Count-1 then
    FFocusItem := FItems.Count-1;

  RePaint;
  if wo_FocusItemTriggersOnChange in FOptions then
    DoOnChange;
end;

procedure TpgfBaseComboBox.SetFontDesc(const AValue: string);
begin
  FFont.Free;
  FFont := pgfGetFont(AValue);
  if FAutoSize then
  begin
    Height := FFont.Height + (FMargin * 2);
  end;
  RePaint;
end;

procedure TpgfBaseComboBox.SetExtraHint(const AValue: string);
begin
  if FExtraHint = AValue then
    Exit; //==>
  FExtraHint := AValue;
  Repaint;
end;

procedure TpgfBaseComboBox.SetReadOnly(const AValue: Boolean);
begin
  if FReadOnly = AValue then exit;
  FReadOnly := AValue;
  Repaint;
end;

procedure TpgfBaseComboBox.DisableShowHint;
begin
  FStoredShowHint := ShowHint;
  ShowHint := False;
  fpgApplication.HideHint; // make sure Application hint timer doesn't fire
end;

procedure TpgfBaseComboBox.RestoreShowHint;
begin
  ShowHint := FStoredShowHint;
end;

procedure TpgfBaseComboBox.SetMargin(const AValue: integer);
begin
  if (FMargin = AValue) or (AValue <= 0) then
    Exit; //=>
  FMargin := AValue;
  if FAutoSize then
    Height := FFont.Height + (FMargin * 2);
  Repaint;
end;

procedure TpgfBaseComboBox.SetAutoSize(const AValue: Boolean);
var
  r: TRect;
begin
  if FAutoSize = AValue then
    exit;
  FAutoSize := AValue;
  if FAutoSize then
  begin
    r := fpgStyle.GetControlFrameBorders;
    FHeight := FFont.Height + (Margin*2) + (r.Top+r.Bottom);
    CalculateInternalButtonRect;
    UpdateWindowPosition;
  end;
end;

procedure TpgfBaseComboBox.CalculateInternalButtonRect;
begin
  FInternalBtnRect.SetRect(Width - Min(Height, 20), 2, Min(Height, 20)-2, Height-4);
end;

procedure TpgfBaseComboBox.InternalOnClose(Sender: TObject);
begin
  DoOnCloseUp;
  RestoreShowHint;
end;

procedure TpgfBaseComboBox.InternalItemsChanged(Sender: TObject);
begin
  if FItems.Count = 0 then
    FocusItem := -1;
  Repaint;
end;

procedure TpgfBaseComboBox.HandleKeyPress(var keycode: word;
  var shiftstate: TShiftState; var consumed: boolean);
var
  old: integer;
begin
  inherited HandleKeyPress(keycode, shiftstate, consumed);
  if not consumed then
  begin
    if ReadOnly then
      Exit;
    old := FocusItem;
    case keycode of
      keyDown:
        begin
          if (ssAlt in shiftstate) then
            DoDropDown
          else
          begin
            FocusItem := FocusItem + 1;
            if old <> FocusItem then
              DoOnChange;
            consumed := True;
          end;
        end;

      keyUp:
        begin
          if (FocusItem = 0) and (wo_AllowUserBlank in FOptions) then
            FocusItem := FocusItem - 1
          else if FocusItem > 0 then
            FocusItem := FocusItem - 1;
          if old <> FocusItem then
            DoOnChange;
          consumed := True;
        end;
    end;  { case }
  end;  { if }
end;

procedure TpgfBaseComboBox.DoOnChange;
begin
  if Assigned(OnChange) then
    FOnChange(self);
end;

procedure TpgfBaseComboBox.DoOnDropDown;
begin
  if Assigned(OnDropDown) then
    FOnDropDown(self);
end;

procedure TpgfBaseComboBox.DoOnCloseUp;
begin
  if Assigned(OnCloseUp) then
    OnCloseUp(self);
end;

procedure TpgfBaseComboBox.PaintInternalButton;
var
  ar: TpgfRect;
  btnflags: TpgfButtonFlags;
begin
  Canvas.BeginDraw;
  btnflags := [];
  ar := FInternalBtnRect;

  { The bounding rectangle for the arrow }
  ar.Width := 8;
  ar.Height := 6;
  ar.Left := FInternalBtnRect.Left + ((FInternalBtnRect.Width-ar.Width) div 2);
  ar.Top := FInternalBtnRect.Top + ((FInternalBtnRect.Height-ar.Height) div 2);

  if FBtnPressed then
  begin
    Include(btnflags, btfIsPressed);
    OffsetRect(ar, 1, 1);
  end;
  // paint button face
  fpgStyle.DrawButtonFace(Canvas,
      FInternalBtnRect.Left,
      FInternalBtnRect.Top,
      FInternalBtnRect.Width,
      FInternalBtnRect.Height, btnflags);
  if Enabled then
    Canvas.SetColor(clText1)
  else
    Canvas.SetColor(clShadow1);

  // paint arrow
  fpgStyle.DrawDirectionArrow(Canvas, ar.Left, ar.Top, ar.Width, ar.Height, adDown);
  Canvas.EndDraw(FInternalBtnRect);
end;

function TpgfBaseComboBox.GetDropDownPos(AParent, AComboBox, ADropDown: TpgfWidget): TpgfRect;
var
  pt: TPoint;
begin
  // translate ComboBox coordinates
  pt := WindowToScreen(AParent, Point(AComboBox.Left, AComboBox.Bottom));

  // dropdown will not fit below combobox so we place it above
  if (pt.y + ADropDown.Height) > fpgApplication.ScreenHeight then
    Result.Top := AComboBox.Top - ADropDown.Height
  else
    Result.Top := AComboBox.Bottom;

  // dropdown height doesn't fit in screen height so shrink it
  if (ADropDown.Height > fpgApplication.ScreenHeight) then
  begin
    // 50 is just some spacing for taskbars (top or bottom aligned)
    Result.Top    := AComboBox.Top - pt.y + 50;
    Result.Height := fpgApplication.ScreenHeight - 50;
  end
  else
    Result.Height := ADropDown.Height;

  Result.Left   := AComboBox.Left;
  Result.Width  := ADropDown.Width;
end;

constructor TpgfBaseComboBox.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FWidth          := 120;
  FHeight         := 24;
  FAutoSize       := False;
  FDropDownCount  := 8;
  FMargin         := 1;
  FFocusItem      := -1; // nothing is selected
  FReadOnly       := False;
  FItems := TStringList.Create;
  FItems.OnChange := @InternalItemsChanged;
  FFont := fpgGetFont('#List');
  FOptions := [];
  FBtnPressed := False;
  FOnChange := nil;
  FExtraHint := '';
  FStoredShowHint := ShowHint;
end;

destructor TpgfBaseComboBox.Destroy;
begin
  FFont.Free;
  FItems.Free;
  inherited Destroy;
end;

{ TComboboxDropdownWindow }

procedure TComboboxDropdownWindow.SetFirstItem;
begin
  // If FocusItem is less than DropDownCount FirsItem = 0
  if ListBox.FocusItem+1 <= FCallerWidget.DropDownCount then
    ListBox.SetFirstItem(0)
  // If FocusItem is in the last DropDownCount of items
  else if (ListBox.ItemCount - (ListBox.FocusItem+1)) < FCallerWidget.DropDownCount then
    ListBox.SetFirstItem(ListBox.ItemCount - FCallerWidget.DropDownCount)
  else
  // Try and centre FocusItem in the drow down window
    ListBox.SetFirstItem(ListBox.FocusItem - (FCallerWidget.DropDownCount div 2));
end;

procedure TComboboxDropdownWindow.ListBoxSelect(Sender: TObject);
begin
  FCallerWidget.FocusItem := ListBox.FocusItem;
  if not (wo_FocusItemTriggersOnChange in FCallerWidget.FOptions) then
    FCallerWidget.DoOnChange;
  Close;
end;

procedure TComboboxDropdownWindow.HandleShow;
begin
  ListBox.SetPosition(0, 0, Width, Height);
  inherited HandleShow;
  SetFirstItem;
  ListBox.SetFocus;
end;

procedure TComboboxDropdownWindow.HandleKeyPress(var keycode: word;
  var shiftstate: TShiftState; var consumed: boolean);
begin
  inherited HandleKeyPress(keycode, shiftstate, consumed);
  if KeyCode = keyEscape then
  begin
    Close;
  end
end;

constructor TComboboxDropdownWindow.Create(AOwner: TComponent; ACallerWidget: TpgfBaseStaticCombo);
begin
  inherited Create(nil);
  Name := '_ComboboxDropdownWindow';
  if not Assigned(ACallerWidget) then
    raise Exception.Create('ACallerWidget may not be <nil>');
  FCallerWidget := ACallerWidget;

  FListBox := CreateListBox(self, 0, 0, 80, 100);
  FListbox.Name := '_ComboboxDropdownWindowListBox';
  FListBox.PopupFrame := True;
  FListBox.Items.Assign(FCallerWidget.Items);
  FListBox.FocusItem := FCallerWidget.FocusItem;
  FListBox.OnSelect := @ListBoxSelect;
end;



function CreateComboBox(AOwner: TComponent; x, y, w: TpgfCoord; AList: TStringList;
      h: TpgfCoord = 0): TpgfComboBox;
begin
  Result           := TpgfComboBox.Create(AOwner);
  Result.Left      := x;
  Result.Top       := y;
  Result.Width     := w;
  Result.Focusable := True;

  if h < TpgfComboBox(Result).FFont.Height + (Result.FMargin * 2) then
    Result.Height := TpgfComboBox(Result).FFont.Height + (Result.FMargin * 2)
  else
    Result.Height := h;

  if Assigned(AList) then
    Result.Items.Assign(AList);
end;

{ TpgfBaseStaticCombo }

function TpgfBaseStaticCombo.GetText: string;
begin
  if (FocusItem >= 0) and (FocusItem < FItems.Count) then
    Result := Items.Strings[FocusItem]
  else
    Result := '';
end;

function TpgfBaseStaticCombo.HasText: boolean;
begin
  Result := FocusItem >= 0;
end;

procedure TpgfBaseStaticCombo.DoDropDown;
var
  ddw: TComboboxDropdownWindow;
  rowcount: integer;
  r: TpgfRect;
begin
  {$IFDEF DEBUG}
  SendMethodEnter('TpgfBaseStaticCombo.DoDropDown');
  {$ENDIF}
  if (not Assigned(FDropDown)) or (not FDropDown.HasHandle) then
  begin
    {$IFDEF DEBUG}
    SendDebug('.... creating');
    {$ENDIF}
    FreeAndNil(FDropDown);
    DisableShowHint;  // disable hints while dropdown is visible

    FDropDown := TComboboxDropdownWindow.Create(nil, self);
    ddw := TComboboxDropdownWindow(FDropDown);

    // adjust the height of the dropdown
    rowcount := FItems.Count;
    if rowcount > FDropDownCount then
      rowcount := FDropDownCount;
    if rowcount < 1 then
      rowcount := 1;  // Even if empty at least show one line dropdown

    ddw.Width   := Width;
    ddw.Height  := (ddw.ListBox.RowHeight * rowcount) + 4;
    ddw.DontCloseWidget := self;  // now we can control when the popup window closes
    r := GetDropDownPos(Parent, self, ddw);  // find suitable position
    ddw.Height := r.Height;  // in case GetDropDownPos resized us
    
    if (FItems.Count > 0) then
      DoOnDropDown;
    ddw.OnClose := @InternalOnClose;
    
    ddw.ShowAt(Parent, r.Left, r.Top);
  end
  else
  begin
    {$IFDEF DEBUG}
    SendDebug('.... destroying');
    {$ENDIF}
    FBtnPressed := False;
    ddw := TComboboxDropdownWindow(FDropDown);
    ddw.Close;
    FreeAndNil(FDropDown);
  end;
end;

procedure TpgfBaseStaticCombo.DoDrawText(const ARect: TpgfRect);
var
  flags: TpgfTextFlags;
begin
  // Draw select item's text
  flags := [txtLeft, txtVCenter];
  if not Enabled then
    flags += [txtDisabled];
  if HasText then
    Canvas.DrawText(ARect, Text, flags)
  else
  begin
    Canvas.SetTextColor(clShadow1);
    Canvas.DrawText(ARect, ExtraHint, flags);
  end;
end;

procedure TpgfBaseStaticCombo.InternalBtnClick(Sender: TObject);
begin
  DoDropDown;
end;

procedure TpgfBaseStaticCombo.SetText(const AValue: string);
var
  i: integer;
begin
  if ReadOnly then
    Exit;

  if AValue = '' then
    SetFocusItem(-1)  // nothing selected
  else
  begin
    for i := 0 to FItems.Count-1 do
    begin
      if SameText(Items.Strings[i], AValue) then
      begin
        SetFocusItem(i);
        Exit; //==>
      end;
    end;
    // if we get here, we didn't find a match
    SetFocusItem(-1);
  end;
end;

procedure TpgfBaseStaticCombo.HandleResize( AWidth, AHeight: TpgfCoord);
begin
  inherited HandleResize(AWidth, AHeight);
  if FSizeIsDirty then
    CalculateInternalButtonRect;
end;

procedure TpgfBaseStaticCombo.HandleKeyPress(var keycode: word; var shiftstate: TShiftState; var consumed: boolean);
begin
  inherited HandleKeyPress(keycode, shiftstate, consumed);
  if consumed then
    RePaint;
end;

procedure TpgfBaseStaticCombo.HandleLMouseDown(x, y: integer; shiftstate: TShiftState);
begin
  inherited HandleLMouseDown(x, y, shiftstate);
  // button state is down only if user clicked in the button rectangle.
  FBtnPressed := PtInRect(FInternalBtnRect, Point(x, y));
  PaintInternalButton;
  DoDropDown;
end;

procedure TpgfBaseStaticCombo.HandleLMouseUp(x, y: integer; shiftstate: TShiftState);
begin
  inherited HandleLMouseUp(x, y, shiftstate);
  FBtnPressed := False;
  PaintInternalButton;
end;

procedure TpgfBaseStaticCombo.HandleMouseScroll(x, y: integer;
  shiftstate: TShiftState; delta: smallint);
var
  NewIndex: Integer;
begin
  if (FDropDown <> nil) and FDropDown.Visible then
    Exit; //==>
  if Items.Count < 1 then
    Exit; //==>

  NewIndex := FocusItem + Delta;

  if NewIndex > Items.Count-1 then
    NewIndex := Items.Count-1;
    
  if NewIndex < 0 then
    NewIndex := 0;
    
  if NewIndex <> FocusItem then
  begin
    FocusItem := NewIndex;
    RePaint;
  end;
end;

procedure TpgfBaseStaticCombo.HandlePaint;
var
  r: TpgfRect;
begin
//  inherited HandlePaint;
  Canvas.ClearClipRect;
  r.SetRect(0, 0, Width, Height);
  Canvas.DrawControlFrame(r);

  // internal background rectangle (without frame)
  InflateRect(r, -2, -2);
  Canvas.SetClipRect(r);

  if Enabled then
  begin
    if ReadOnly then
      Canvas.SetColor(clWindowBackground)
    else
      Canvas.SetColor(FBackgroundColor);
  end
  else
    Canvas.SetColor(clWindowBackground);

  Canvas.FillRectangle(r);

  // paint the fake dropdown button
  PaintInternalButton;

  Dec(r.Width, FInternalBtnRect.Width);
  Canvas.SetClipRect(r);
  Canvas.SetFont(Font);

  if Focused then
  begin
    Canvas.SetColor(clSelection);
    Canvas.SetTextColor(clSelectionText);
    InflateRect(r, -1, -1);
    Canvas.FillRectangle(r);
  end
  else
  begin
    Canvas.SetTextColor(FTextColor);
  end;

  { adjust rectangle size smaller for text }
  r.Left := r.Left + Margin;
  r.Width := r.Width - (Margin*2);
  DoDrawText(r);
end;

constructor TpgfBaseStaticCombo.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FBackgroundColor  := clBoxColor;
  FTextColor        := Parent.TextColor;
  FFocusable        := True;

  CalculateInternalButtonRect;
end;

destructor TpgfBaseStaticCombo.Destroy;
begin
  FDropDown.Free;
  inherited Destroy;
end;

procedure TpgfBaseStaticCombo.Update;
begin
  FFocusItem := -1;
  Repaint;
end;

end.

