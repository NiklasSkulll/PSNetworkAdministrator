using System.ComponentModel;
using System.Windows.Input;

namespace PSNetworkAdministrator.Gui.ViewModels;

public class TitleBarViewModel : INotifyPropertyChanged
{
    // === events for window control ===
    public event EventHandler? MinimizeRequested;
    public event EventHandler? MaximizeRequested;
    public event EventHandler? CloseRequested;

    // === propertys

    // window state property
    private bool _isMaximized;
    public bool IsMaximized
    {
        get => _isMaximized;
        set
        {
            if (_isMaximized != value)
            {
                _isMaximized = value;
                OnPropertyChanged(nameof(IsMaximized));
                OnPropertyChanged(nameof(MaximizeIconKind));  // update icon
            }
        }
    }

    // === dynamic icon "Kind" ===
    public string MaximizeIconKind => IsMaximized ? "WindowRestore" : "WindowMaximize";

    // === commands ===
    public ICommand MinimizeCommand { get; }
    public ICommand MaximizeCommand { get; }
    public ICommand CloseCommand { get; }

    // === constructor ===
    public TitleBarViewModel()
    {
        MinimizeCommand = new RelayCommand(_ => MinimizeRequested?.Invoke(this, EventArgs.Empty));
        MaximizeCommand = new RelayCommand(_ => MaximizeRequested?.Invoke(this, EventArgs.Empty));
        CloseCommand = new RelayCommand(_ => CloseRequested?.Invoke(this, EventArgs.Empty));
    }

    // === INotifyPropertyChanged ===
    public event PropertyChangedEventHandler? PropertyChanged;
    protected void OnPropertyChanged(string propertyName)
    {
        PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
    }
}