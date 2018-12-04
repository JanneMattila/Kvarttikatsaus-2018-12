using System.Web.Mvc;

namespace Kvarttikatsaus.Controllers
{
    public class HomeController : Controller
    {
        public ActionResult Index()
        {
            return View();
        }
    }
}