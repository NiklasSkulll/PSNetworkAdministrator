using System.Windows;
using System.Windows.Input;
using PSNetworkAdministrator.Gui.ViewModels;

namespace PSNetworkAdministrator.Gui.Views;

public partial class MainWindow : Window
{
    private MainWindowViewModel? _viewModel;
    public MainWindow()
    {
        InitializeComponent();

        _viewModel = new MainWindowViewModel();
        DataContext = _viewModel;

        // subscribe to TitleBar events
        _viewModel.TitleBarVM.MinimizeRequested += (s, e) => WindowState = WindowState.Minimized;
        _viewModel.TitleBarVM.MaximizeRequested += (s, e) =>
        {
            WindowState = WindowState == WindowState.Maximized 
                ? WindowState.Normal 
                : WindowState.Maximized;
            // update ViewModel state after changing window state
            _viewModel.TitleBarVM.IsMaximized = (WindowState == WindowState.Maximized);
        };
        _viewModel.TitleBarVM.CloseRequested += (s, e) => Close();

        // subscribe to window StateChanged event to track all state changes
        this.StateChanged += (s, e) => 
        {
            _viewModel.TitleBarVM.IsMaximized = (WindowState == WindowState.Maximized);
        };

        // set initial state
        _viewModel.TitleBarVM.IsMaximized = (WindowState == WindowState.Maximized);
    }

    // drag window when app window is clicked
    private void TitleBarMouseLeftButtonDown(object sender, MouseButtonEventArgs e)
    {
        if (e.ClickCount == 2)
        {
            WindowState = WindowState == WindowState.Maximized 
                ? WindowState.Normal 
                : WindowState.Maximized;
            // update ViewModel after double-click maximize/restore
            _viewModel.TitleBarVM.IsMaximized = (WindowState == WindowState.Maximized);
        }
        else
        {
            DragMove();
        }
    }
}