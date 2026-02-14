using System.Globalization;
using System.Windows;
using System.Windows.Data;

namespace PSNetworkAdministrator.Gui.Converters;

public class BoolToVisibilityConverter : IValueConverter
{
    // "Convert": bool to "Visibility" (when ViewModel changes)
    public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
    {
        if (value is bool boolValue)
        {
            return boolValue ? Visibility.Visible : Visibility.Collapsed;
        }
        return Visibility.Collapsed;
    }

    // "ConvertBack": "Visibility" to bool (when UI changes)
    public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
    {
        if (value is Visibility visibility)
        {
            return visibility == Visibility.Visible;
        }
        return false;
    }
}