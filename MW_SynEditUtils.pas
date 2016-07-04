unit MW_SynEditUtils;
interface

// =================================================================================================
// Mageware RAD Utilities
// Magetech (PTY) Ltd.
// Mike Heydon JUL 2016
//
// SynEditUtils
// ------------
// Enhancements and helper classes for SynEdit components.
// SynEdit version used v 1.32.1 2012/19/09 10:50:00 CodehunterWorks Exp
//
// TSynEditOptionsConfig Class
// ---------------------------
// Documentation of how to load and save Editor options in SynEdit is sorely lacking on the web.
// Needed to dig into code to find out how the mechanism worked.
// This class is a nice and simple way to manage this functionality without having to dig into
// the code each time to remeber how to do it.
// Most methods are static (class methods) and can be called without creating and instance of
// the class.
// eg. TSynEditOptionsConfig.LoadFromFile(AMySynEditObj);
//
// TSynEditKeyUtils Class
// ----------------------
// Utilities to assist in Keytroke processing and information text.
// All methods are static and can be called without creating and instance of the class.
// eg. TSynEditKeyUtils.GetKeystrokesHelp(AMySynEditObj,ATextList);
//
// TSynEditAutoPopup Class
// -----------------------
// Class that attaches and controls a Popup menu for the passed SynEdit. Dropdown includes
// Cut,Copy,Paste,Select All,Undo,Redo and Goto. The dropdown caption displays the correct
// shortcut descriptions as set vi the SynEdit options dialog.
//
// TSynEditStatusBar Class
// -----------------------
// Generic Status bar handler class for SynEdit incorporating Row/Line number, Insert and Modified
// flags. Attaches to passed StnEdit object.
//
// Code is for Delphi 2010 and upward.
// Multi Platform additions need to be added for Free Pascal, Lazarus, Linux etc.
// =================================================================================================

uses Forms, Classes, SysUtils, ClipBrd, Menus, StdCtrls, Controls, ComCtrls, SynEdit,
     SynEditOptionsDialog, SynEditKeyCmds;

type
    // ================================================================================
    // Class with static methods to facilitate loading, editing and saving SynEdit
    // Options from and to .opt file. Method Edit wil automatically save to the .opt
    // file when closed unless parameter "AAutoSave=false" in which case the user will
    // use the SaveToFile method.
    // ================================================================================

    TSynEditOptionsConfig = class(TObject)
    public
      class procedure LoadFromFile(ASynEdit : TSynEdit);
      class procedure SaveToFile(ASynEdit : TSynEdit);
      class procedure DoEditConfig(ASynEdit : TSynEdit; AAutoSave : boolean = true);
    end;

    // ================================================================================
    // Class with static methods to facilitate processing and getting readable text
    // information about SynEdit Keystrokes.
    // ================================================================================

    TSynEditKeyUtils = class(TObject)
    public
      class procedure GetKeystrokesHelp(ASynEdit : TSynEdit; AList : TStrings);
      class function GetKeyShortcut(ASynEdit : TSynEdit; AKeyValueEC : integer) : string;
    end;

    // ===============================================================================
    // Class that attaches and controls a Popup menu for the passed SynEdit. Dropdown
    // includes Cut,Copy,Paste,Select All,Undo,Redo and Goto. The dropdown caption
    // displays the correct shortcutdescriptions as set vi the SynEdit options
    // dialog. NOTE: GotoRow
    // ===============================================================================

    TSynEditAutoPopup = class(TObject)
    private
      FSynEdit : TSynEdit;
      FPopup : TPopupmenu;
      FGotoShortCut : string;
      procedure _EventPopup(ASender : TObject);
      procedure _EventCut(ASender : TObject);
      procedure _EventCopy(ASender : TObject);
      procedure _EventPaste(ASender : TObject);
      procedure _EventSelectAll(ASender : TObject);
      procedure _EventUndo(ASender : TObject);
      procedure _EventRedo(ASender : TObject);
      procedure _EventKeyPress(ASender : TObject; var AKey : Char);
      procedure _EventGotoRow(ASender : TObject);
      procedure _BuildPopup;

    public
      constructor Create(ASynEdit : TSynEdit; const AGotoShortCut : string = 'CTRL+G');
      destructor Destroy; override;
      property GotoShortCut : string read FGotoShortCut write FGotoShortCut;
    end;

   // =============================================================================
   // Generic Status bar handler class for SynEdit incorporating Row/Line number,
   // Insert and Modified flags. Attaches to passed StnEdit object.
   // =============================================================================

   TSynEditStatusBar = class(TObject)
   private
     FSynEdit : TSynEdit;
     FStatusBar : TStatusBar;
     FIsModified : boolean;
     procedure _EventStatusChange(ASender : TObject; AChanges : TSynStatusChanges);
     procedure _ConfigureStatusBar;

   public
     constructor Create(ASynEdit : TSynEdit; AStatusBar : TStatusBar);
     destructor Destroy; override;
   end;

// -------------------------------------------------------------------------------------------------
implementation

{$REGION 'TSynEditOptionsConfig Class'}

// ========================================================================================
// Read and load editor settings from .OPT file and assign to passed TSynEdit component
// Options config filename will be in same dir as EXE and called <ExeName>.opt
// ========================================================================================

class procedure TSynEditOptionsConfig.LoadFromFile(ASynEdit : TSynEdit);
var sOptFile : string;
    oOpt : TSynEditorOptionsContainer;
    oStream : TFileStream;
begin
  sOptFile := ChangeFileExt(ParamStr(0),'.opt');
  oOpt := TSynEditorOptionsContainer.Create(nil);

  try
    oStream := TFileStream.Create(sOptFile,fmOpenRead);
    oStream.ReadComponent(oOpt);
    oOpt.AssignTo(ASynEdit);
  except
    // If file does not exist or error in format while loading
    // then ignore the error and the TSynEdit component will
    // have the default Option properties.
  end;

  FreeAndNil(oStream);
  FreeAndNil(oOpt);
end;

// ========================================================================================
// Save the current editor settings to .OPT file from passed TSynEdit component
// Options config filename will be in same dir as EXE and called <ExeName>.opt
// ========================================================================================

class procedure TSynEditOptionsConfig.SaveToFile(ASynEdit : TSynEdit);
var sOptFile : string;
    oOpt : TSynEditorOptionsContainer;
    oStream : TFileStream;
begin
  sOptFile := ChangeFileExt(ParamStr(0),'.opt');
  oOpt := TSynEditorOptionsContainer.Create(nil);
  oOpt.Assign(ASynEdit);
  oStream := TFileStream.Create(sOptFile,fmCreate);

  try
    oStream.WriteComponent(oOpt);
  finally
    FreeAndNil(oStream);
    FreeAndNil(oOpt);
  end;
end;

// ==============================================================================
// Edit the Options config of the passed TSynEdit component in a dialog form.
// Will autosave to the .OPT file if AAutoSave is NOT specified or set to TRUE
// If set to FALSE then no save occurs and the user can save manually via
// method SaveToFile
// ==============================================================================

class procedure TSynEditOptionsConfig.DoEditConfig(ASynEdit : TSynEdit;
                                                   AAutoSave : boolean = true);
var oOptDlg : TSynEditOptionsDialog;
    oOpt : TSynEditorOptionsContainer;
begin
  oOptDlg := TSynEditOptionsDialog.Create(nil);
  oOpt := TSynEditorOptionsContainer.Create(nil);
  oOpt.Assign(ASynEdit);

  try
    if oOptDlg.Execute(oOpt) then begin
      oOpt.AssignTo(ASynEdit);
      if AAutoSave then SaveToFile(ASynEdit);
    end;
  finally
    FreeAndNil(oOpt);
    FreeAndNil(oOptDlg);
  end;
end;

{$ENDREGION}

{$REGION 'TSynEditKeyUtils Class'}

// =======================================================
// Load keystroke help text into a TStrings object.
// Each line is a key.value pair seperated by "="
// eg. "Delete Last Word=Ctrl+BkSp"
// =======================================================

class procedure TSynEditKeyUtils.GetKeystrokesHelp(ASynEdit : TSynEdit; AList : TStrings);
var i,ii,iPos,iLen : integer;
    sText,sKey,sName : string;
begin
  AList.Clear;
  AList.BeginUpdate;

  try
    for i := 0 to ASynEdit.Keystrokes.Count - 1 do begin
      sText := ASynEdit.Keystrokes.Items[i].DisplayName;
      iPos := pos('-',sText);
      sName := trim(copy(sText,iPos + 1));
      sKey := trim(copy(sText,3,iPos - 3));
      // Expand "Sel" to "Select"
      if pos('Select',sKey) = 0 then sKey := StringReplace(sKey,'Sel','Select',[rfReplaceAll]);
      // Break into whole words
      iLen := length(sKey);
      for ii := iLen downto 2 do if sKey[ii] = Upcase(sKey[ii]) then Insert(' ',sKey,ii);
      AList.Add(sKey + '=' + sName);
    end;
  finally
    AList.EndUpdate;
  end;
end;


// ==========================================================================================
// Return the shortcut Key Description of a passed Key Command as specified as constants
// in SynEdit unit SysEditKeyCmds.
// eg. TSynEditKeyUtils.GetKeyShortcut(MySynEdit,ecSelWordRight);
//     could return "Shift+Ctrl+Right"
// Will return NULL string if key command is NOT assigned.
// ==========================================================================================

class function TSynEditKeyUtils.GetKeyShortcut(ASynEdit : TSynEdit; AKeyValueEC : integer) : string;
var sResult,sText : string;
    iIdx,iPos : integer;
begin
  sResult := '';
  iIdx := ASynEdit.Keystrokes.FindCommand(AKeyValueEC);

  if iIdx >= 0 then begin
    sText := ASynEdit.Keystrokes.Items[iIdx].DisplayName;
    iPos := pos('-',sText);
    sResult := trim(copy(sText,iPos + 1));
  end;

  Result := sResult;
end;

{$ENDREGION}

{$REGION 'TSynEditAutoPopup Class'}

// =================================
// Constructors and Destructors
// =================================

constructor TSynEditAutoPopup.Create(ASynEdit : TSynEdit; const AGotoShortCut : string = 'CTRL+G');
begin
  inherited Create;

  FGotoShortCut := AGotoShortCut;
  FSynEdit := ASynEdit;
  FPopup := TPopupmenu.Create(nil);
  _BuildPopup;
  // Attach Popup menu to SynEdit
  FSynEdit.PopupMenu := FPopup;
end;

destructor TSynEditAutoPopup.Destroy;
begin
  FSynEdit.PopupMenu := nil;
  FreeAndNil(FPopup);
  FSynEdit := nil;

  inherited Destroy;
end;

// =====================================================================
// Dynamically build the auto popup and assign events to the items
// and before popup
// =====================================================================

procedure TSynEditAutoPopup._BuildPopup;
var oItem : TMenuItem;
begin
  oItem := TMenuItem.Create(FPopup);
  oItem.Caption := 'Cut';
  oItem.OnClick := _EventCut;
  FPopup.Items.Add(oItem);

  oItem := TMenuItem.Create(FPopup);
  oItem.Caption := 'Copy';
  oItem.OnClick := _EventCopy;
  FPopup.Items.Add(oItem);

  oItem := TMenuItem.Create(FPopup);
  oItem.Caption := 'Paste';
  oItem.OnClick := _EventPaste;
  FPopup.Items.Add(oItem);

  oItem := TMenuItem.Create(FPopup);
  oItem.Caption := 'Select All';
  oItem.OnClick := _EventSelectAll;
  FPopup.Items.Add(oItem);

  oItem := TMenuItem.Create(FPopup);
  oItem.Caption := '-';
  FPopup.Items.Add(oItem);

  oItem := TMenuItem.Create(FPopup);
  oItem.Caption := 'Undo';
  oItem.OnClick := _EventUndo;
  FPopup.Items.Add(oItem);

  oItem := TMenuItem.Create(FPopup);
  oItem.Caption := 'Redo';
  oItem.OnClick := _EventRedo;
  FPopup.Items.Add(oItem);

  oItem := TMenuItem.Create(FPopup);
  oItem.Caption := 'Goto Row';
  oItem.OnClick := _EventGotoRow;
  oItem.ShortCut := TextToShortCut(FGotoShortCut);
  FPopup.Items.Add(oItem);

  FPopup.OnPopup := _EventPopup;
end;

// ======================================================================
// Respond to the before Popup event and refresh captions and item
// enabled/disabled states
// ======================================================================

procedure TSynEditAutoPopup._EventPopup(ASender : TObject);
var oItem : TMenuItem;
begin
  // Refresh captions in case shortcuts changed by options editor and set enabled/disabled state
  oItem := FPopup.Items[0]; // Cut function
  oItem.Caption := 'Cut' + char(9) + TSynEditKeyUtils.GetKeyShortcut(FSynEdit,ecCut);
  oItem.Enabled := FSynEdit.SelLength <> 0;
  oItem := FPopup.Items[1]; // Copy function
  oItem.Caption := 'Copy' + char(9) + TSynEditKeyUtils.GetKeyShortcut(FSynEdit,ecCopy);
  oItem.Enabled := FSynEdit.SelLength <> 0;
  oItem := FPopup.Items[2]; // Paste function
  oItem.Caption := 'Paste' + char(9) + TSynEditKeyUtils.GetKeyShortcut(FSynEdit,ecPaste);
  oItem.Enabled := Clipboard.AsText <> '';
  oItem := FPopup.Items[3]; // Select All function
  oItem.Caption := 'Select All' + char(9) + TSynEditKeyUtils.GetKeyShortcut(FSynEdit,ecSelectAll);
  oItem := FPopup.Items[5]; // Undo function
  oItem.Caption := 'Undo' + char(9) + TSynEditKeyUtils.GetKeyShortcut(FSynEdit,ecUndo);
  oItem := FPopup.Items[6]; // Redo function
  oItem.Caption := 'Redo' + char(9) + TSynEditKeyUtils.GetKeyShortcut(FSynEdit,ecRedo);
end;

// ==================================
// Popupmenu Item Event actions
// ==================================

procedure TSynEditAutoPopup._EventCut(ASender : TObject);
begin
  FSynEdit.CutToClipboard;
end;

procedure TSynEditAutoPopup._EventCopy(ASender : TObject);
begin
  FSynEdit.CopyToClipboard;
end;

procedure TSynEditAutoPopup._EventPaste(ASender : TObject);
begin
  FSynEdit.PasteFromClipboard;
end;

procedure TSynEditAutoPopup._EventSelectAll(ASender : TObject);
begin
  FSynEdit.SelectAll;
end;

procedure TSynEditAutoPopup._EventUndo(ASender : TObject);
begin
  FSynEdit.Undo;
end;

procedure TSynEditAutoPopup._EventRedo(ASender : TObject);
begin
  FSynEdit.Redo;
end;

// ================================================================
// Only allow numeric characters 0..9,BkSpace and Movement keys
// ================================================================

procedure TSynEditAutoPopup._EventKeyPress(ASender : TObject; var AKey : Char);
begin
  if ((AKey < '0') or (AKey > '9')) and (AKey <> #8) then AKey := #0;
end;

// ====================
// Goto Row Number
// ====================

procedure TSynEditAutoPopup._EventGotoRow(ASender : TObject);
var iRow : integer;
    oForm : TForm;
    oEdit : TEdit;
    oButton : TButton;
begin
  // Construct a Form
  oForm := TForm.Create(nil);
  oForm.BringToFront;
  oForm.Position := poScreenCenter;
  oForm.BorderStyle := bsDialog;
  oForm.BorderIcons := [biSystemMenu];
  oForm.Caption := 'Goto Row';
  oForm.Height := 80;
  oForm.Width := 100;
  // Construct an Edit box with numeric chars only
  oEdit := TEdit.Create(oForm);
  oEdit.Parent := oForm;
  oEdit.OnKeyPress := _EventKeyPress;
  oEdit.AlignWithMargins := true;
  oEdit.MaxLength := FSynEdit.Gutter.DigitCount;
  oEdit.Align := alTop;
  // Construct OK Button
  oButton := TButton.Create(oForm);
  oButton.Parent := oForm;
  oButton.Caption := 'OK';
  oButton.ModalResult := mrOk;
  oButton.Default := true;
  oButton.Align := alBottom;

  if oForm.ShowModal = mrOk then begin
    FSynEdit.SetFocus;
    iRow := StrToIntDef(oEdit.Text,0) - FSynEdit.Gutter.LineNumberStart + 1;
    FSynEdit.CaretY := iRow;
    FSynEdit.CaretX := 0;
  end;

  FreeAndNil(oForm);
end;

{$ENDREGION}

{$REGION 'TSynEditStatusBar Class'}

// ===============================
// Constructors and Destructors
// ===============================

constructor TSynEditStatusBar.Create(ASynEdit : TSynEdit; AStatusBar : TStatusBar);
begin
  inherited Create;

  FIsModified := false;
  FSynEdit := ASynEdit;
  FStatusBar := AStatusBar;
  _ConfigureStatusBar;
  _EventStatusChange(nil,[]);
  FSynEdit.OnStatusChange := _EventStatusChange;
end;

destructor TSynEditStatusBar.Destroy;
begin
  FSynEdit.OnStatusChange := nil;
  FStatusBar := nil;
  FSynEdit := nil;

  inherited Destroy;
end;

// ========================================================
// Configire StatusBar
// NOTE: Will destroy any current panels in the bar
// ========================================================

procedure TSynEditStatusBar._ConfigureStatusBar;
var oStatusPanel : TStatusPanel;
begin
  // Configure the status bar
  FStatusBar.SimplePanel := false;
  FStatusBar.Panels.Clear;
  // Line number panel
  oStatusPanel := FStatusbar.Panels.Add;
  oStatusPanel.Text := 'Line:';
  oStatusPanel.Width := 70;
  // Row number panel
  oStatusPanel := FStatusbar.Panels.Add;
  oStatusPanel.Text := 'Row:';
  oStatusPanel.Width := 70;
  // Insert mode panel
  oStatusPanel := FStatusbar.Panels.Add;
  oStatusPanel.Width := 70;
  oStatusPanel.Alignment := taCenter;
  // Modified flag panel
  oStatusPanel := FStatusbar.Panels.Add;
  oStatusPanel.Width := 70;
  oStatusPanel.Alignment := taCenter;
  // Padding panel
  oStatusPanel := FStatusbar.Panels.Add;
  oStatusPanel.Width := 5000;
end;

// ======================================================================
// Event handle for status changes in SynEdit. Update passed StatusBar
// ======================================================================

procedure TSynEditStatusBar._EventStatusChange(ASender : TObject; AChanges : TSynStatusChanges);
begin
  if AChanges * [scAll, scCaretX, scCaretY] <> [] then begin
    FStatusBar.Panels[0].Text := Format('Line: %7d',[FSynEdit.CaretY]);
    FStatusBar.Panels[1].Text := Format('Col: %4d',[FSynEdit.CaretX]);
  end;

  if scModified in AChanges then FIsModified := true;

  if FIsModified then
    FStatusBar.Panels[3].Text := 'Modified'
  else
    FStatusBar.Panels[3].Text := '';

  if FSynEdit.InsertMode then
    FStatusBar.Panels[2].Text := 'Insert'
  else
    FStatusBar.Panels[2].Text := 'Overwrite';
end;

{$ENDREGION}

end.
