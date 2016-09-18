/**
 * Script name: StripEmailDomainFromUsername
 * Strip email domain from username. sAMAccountName should not contain @.
 */

var SerializedBrokeredIdentityContext = org.keycloak.authentication.authenticators.broker.util.SerializedBrokeredIdentityContext;
var AbstractIdpAuthenticator = org.keycloak.authentication.authenticators.broker.AbstractIdpAuthenticator;

function authenticate(context)
{
    //LOG.info('StripEmailDomainFromUsername.authenticate()');
    
    var clientSession = context.getClientSession();
    var ctx = SerializedBrokeredIdentityContext.readFromClientSession(clientSession, AbstractIdpAuthenticator.BROKERED_CONTEXT_NOTE);
    
    var username = ctx.getUsername(); 
    var domainPos = username.indexOf('@');
    if (domainPos > 0) {
        ctx.setUsername(username.substring(0, domainPos));
    }
    
    ctx.saveToClientSession(clientSession, AbstractIdpAuthenticator.BROKERED_CONTEXT_NOTE);
    
    context.success();
}
