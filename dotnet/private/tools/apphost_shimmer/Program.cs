using System.IO;

namespace ApphostShimmer
{
  public class Program
  {
    public static void Main(string[] args)
    {
      var apphost = args[0];
      var dll = args[1];

      new AppHostShellShimMaker(apphost).CreateApphostShellShim(dll, Path.ChangeExtension(dll, ".exe"));
    }
  }
}
