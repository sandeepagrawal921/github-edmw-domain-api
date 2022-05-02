using Edmw.DomainValue.Data.Context;
using Edmw.DomainValue.Data.Entity;
using Edmw.DomainValue.Data.Interfaces;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Linq.Expressions;
using System.Threading.Tasks;

namespace Edmw.DomainValue.Data.Repositories
{
    public class DomainValueRepository : IDomainValueRepository
    {
        private readonly DomainValueContext _domainValueContext;

        public DomainValueRepository(DomainValueContext domainValueContext)
        {
            _domainValueContext = domainValueContext;
        }

        public async Task<IEnumerable<DOMAIN_VALUE>> GetDomainValues(Expression<Func<DOMAIN_VALUE, bool>> whereClause)
        {
            return await _domainValueContext.DOMAIN_VALUE.AsNoTracking().Where(whereClause)
                                                                        ?.OrderBy(dmv => dmv.DMV_VAL_SEQ)?.ToListAsync();
        }
    }
}
