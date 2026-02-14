using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Windows.Input;

namespace PSNetworkAdministrator.Gui.ViewModels;

public class DomainListViewModel : INotifyPropertyChanged
{
    // === event for broadcasting messages ===
    public event EventHandler<string>? DomainActionRequested;

    // === properties ===

    // property for ...
    public ObservableCollection<string> Domains { get; set; }

    // property for Domain selection
    private string? _selectedDomain;
    public string? SelectedDomain
    {
        get => _selectedDomain;
        set
        {
            _selectedDomain = value;
            OnPropertyChanged(nameof(SelectedDomain));
            
            // notify anyone listening that a domain was selected
            DomainActionRequested?.Invoke(this, $"Selected: {value}");
        }
    }

    // === commands ===
    public ICommand AddDomainCommand { get; }

    // === constructor ===
    public DomainListViewModel()
    {
        // sample data
        Domains = new ObservableCollection<string>
        {
            "domain1.local",
            "domain2.local"
        };

        AddDomainCommand = new RelayCommand(ExecuteAddDomain);
    }

    // === command methods ===
    private void ExecuteAddDomain(object? parameter)
    {
        // broadcast the message
        DomainActionRequested?.Invoke(this, "AddDomain");
    }

    // === INotifyPropertyChanged ===
    public event PropertyChangedEventHandler? PropertyChanged;
    protected void OnPropertyChanged(string propertyName)
    {
        PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
    }
}