using System;
using System.Collections.Generic;

namespace Edmw.DomainValue.Data.Dto
{
    public class AcgpDetails
    {
        public List<AcgpModel> ACGPList { get; set; }

        public List<Currency> CurrencyList { get; set; }
    }

    public class AcgpModel
    {
        public string GroupID { get; set; }

        public string GroupName { get; set; }

        public DateTime GroupStartdate { get; set; }

        public string GroupCurrency { get; set; }

    }

    public class Currency
    {
        public string CurrencyCode { get; set; }

        public string CurrencyName { get; set; }

    }
}