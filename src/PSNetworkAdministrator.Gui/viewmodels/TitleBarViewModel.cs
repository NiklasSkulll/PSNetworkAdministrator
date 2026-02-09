using System.ComponentModel;
using System.Windows.Input;

namespace PSNetworkAdministrator.Gui.ViewModels;

public class TitleBarViewModel : INotifyPropertyChanged
{
    // === Events for window control ===
    public event EventHandler? MinimizeRequested;
    public event EventHandler? MaximizeRequested;
    public event EventHandler? CloseRequested;

    // === Commands ===
    public ICommand MinimizeCommand { get; }
    public ICommand MaximizeCommand { get; }
    public ICommand CloseCommand { get; }

    // === Constructor ===
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