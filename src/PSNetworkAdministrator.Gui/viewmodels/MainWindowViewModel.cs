using System.ComponentModel;
using System.Windows.Input;

namespace PSNetworkAdministrator.Gui.ViewModels;

public class MainWindowViewModel : INotifyPropertyChanged
{
    // === child ViewModels ===
    public DomainListViewModel DomainListVM { get; }
    public TitleBarViewModel TitleBarVM { get; }

    // === properties for UI Binding ===

    // property for dialog message
    private string _dialogMessage = "";
    public string DialogMessage
    {
        get => _dialogMessage;
        set
        {
            _dialogMessage = value;
            OnPropertyChanged(nameof(DialogMessage));
        }
    }

    // property for dialog visability
    private bool _isDialogVisible = false;
    public bool IsDialogVisible
    {
        get => _isDialogVisible;
        set
        {
            _isDialogVisible = value;
            OnPropertyChanged(nameof(IsDialogVisible));
        }
    }

    // === commands ===
    public ICommand CloseDialogCommand { get; }

    // === constructor ===
    public MainWindowViewModel()
    {
        // Create child ViewModels
        DomainListVM = new DomainListViewModel();
        TitleBarVM = new TitleBarViewModel();

        // listen to the child's events
        DomainListVM.DomainActionRequested += OnDomainActionRequested;

        // create commands
        CloseDialogCommand = new RelayCommand(ExecuteCloseDialog);
    }

    // === event handler - receives messages from child ViewModels ===
    private void OnDomainActionRequested(object? sender, string action)
    {
        // handle different actions
        if (action == "AddDomain")
        {
            DialogMessage = "Add domain clicked!";
            IsDialogVisible = true;
        }
        else if (action.StartsWith("Selected:"))
        {
            DialogMessage = $"Domain {action.Replace("Selected: ", "")} selected!";
            IsDialogVisible = true;
        }
    }

    // === command method ===
    private void ExecuteCloseDialog(object? parameter)
    {
        IsDialogVisible = false;
    }

    // === INotifyPropertyChanged (tells UI to update) ===
    public event PropertyChangedEventHandler? PropertyChanged;

    protected void OnPropertyChanged(string propertyName)
    {
        PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
    }
}