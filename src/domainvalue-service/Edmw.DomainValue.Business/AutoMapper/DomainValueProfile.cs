using AutoMapper;
using Edmw.DomainValue.Data.Dto;
using Edmw.DomainValue.Data.Entity;

namespace Edmw.DomainValue.Business.AutoMapper
{
    public class DomainValueProfile : Profile
    {
        public DomainValueProfile()
        {
            CreateMap<DOMAIN_VALUE, DomainValueInfo>().ReverseMap();
            CreateMap<DomainValueModel, CurrencyModel>()
                    .ForMember(f => f.CurrencyCode, f => f.MapFrom(a => a.DomainValue))
                    .ForMember(f => f.CurrencyName, f => f.MapFrom(a => a.DomainName));

            CreateMap<DOMAIN_VALUE, DomainValueModel>()
                    .ForMember(dvm => dvm.DomainName, dv => dv.MapFrom(dv => dv.DMV_NME))
                    .ForMember(dvm => dvm.DomainValue, dv => dv.MapFrom(dv => dv.DMV_VALUE)); 
        }
    }
}
