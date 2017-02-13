package com.hubspot.baragon.agent.lbs;

import java.io.IOException;
import java.io.StringWriter;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

import com.github.jknack.handlebars.Handlebars;
import com.github.jknack.handlebars.Template;
import com.google.common.base.Throwables;
import com.google.common.collect.Lists;
import com.google.inject.Inject;
import com.google.inject.Singleton;
import com.google.inject.name.Named;
import com.hubspot.baragon.agent.BaragonAgentServiceModule;
import com.hubspot.baragon.agent.config.LoadBalancerConfiguration;
import com.hubspot.baragon.agent.models.LbConfigTemplate;
import com.hubspot.baragon.exceptions.MissingTemplateException;
import com.hubspot.baragon.models.BaragonAgentMetadata;
import com.hubspot.baragon.models.BaragonConfigFile;
import com.hubspot.baragon.models.BaragonService;
import com.hubspot.baragon.models.ServiceContext;
import com.github.jknack.handlebars.Context;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Singleton
public class LbConfigGenerator {
    private final LoadBalancerConfiguration loadBalancerConfiguration;
    private final Map<String, List<LbConfigTemplate>> templates;
    private final BaragonAgentMetadata agentMetadata;

    private static Logger log = LoggerFactory.getLogger(LbConfigGenerator.class);

    @Inject
    public LbConfigGenerator(LoadBalancerConfiguration loadBalancerConfiguration,
                             BaragonAgentMetadata agentMetadata,
                             @Named(BaragonAgentServiceModule.AGENT_TEMPLATES) Map<String, List<LbConfigTemplate>> templates) {
        this.loadBalancerConfiguration = loadBalancerConfiguration;
        this.agentMetadata = agentMetadata;
        this.templates = templates;
    }

    public Collection<BaragonConfigFile> generateConfigsForProject(ServiceContext snapshot) throws MissingTemplateException {
        final Collection<BaragonConfigFile> files = Lists.newArrayList();
        String templateName = snapshot.getService().getTemplateName().or(BaragonAgentServiceModule.DEFAULT_TEMPLATE_NAME);

        List<LbConfigTemplate> matchingTemplates = templates.get(templateName);

        if (templates.get(templateName) != null) {
            for (LbConfigTemplate template : matchingTemplates) {
                final List<String> filenames = getFilenames(template, snapshot.getService());

                final StringWriter sw = new StringWriter();
                final Context context = Context.newBuilder(snapshot).combine("agentProperties", agentMetadata).build();
                try {
                    template.getTemplate().apply(context, sw);
                } catch (Exception e) {
                    throw Throwables.propagate(e);
                }

                for (String filename : filenames) {
                    files.add(new BaragonConfigFile(String.format("%s/%s", loadBalancerConfiguration.getRootPath(), filename), sw.toString()));
                }
            }
        } else {
            throw new MissingTemplateException(String.format("MissingTemplateException : Template %s could not be found", templateName));
        }

        return files;
    }

    public Set<String> getConfigPathsForProject(BaragonService service) {
        final Set<String> paths = new HashSet<>();
        for (Map.Entry<String, List<LbConfigTemplate>> entry : templates.entrySet()) {
            for (LbConfigTemplate template : entry.getValue()) {
                final List<String> filenames = getFilenames(template, service);
                for (String filename : filenames) {
                    paths.add(String.format("%s/%s", loadBalancerConfiguration.getRootPath(), filename));
                }
            }
        }
        return paths;
    }

    private List<String> getFilenames(LbConfigTemplate template, BaragonService service) {
        String filename = handlebars(template.getFilename(), Collections.singletonMap("service", service));
        return Collections.singletonList(filename);
//        switch (template.getFormatType()) {
//            case NONE:
//                return Collections.singletonList(template.getFilename());
//            case SERVICE:
//                return Collections.singletonList(String.format(template.getFilename(), service.getServiceId()));
//            case DOMAIN_SERVICE:
//            default:
//                List<String> filenames = new ArrayList<>();
//                if (!service.getDomains().isEmpty() && (!loadBalancerConfiguration.getDomains().isEmpty() || loadBalancerConfiguration.getDefaultDomain().isPresent())) {
//                    for (String domain : service.getDomains()) {
//                        if (isDomainServed(domain)) {
//                            filenames.add(String.format(template.getFilename(), domain, service.getServiceId()));
//                        }
//                    }
//                    if (filenames.isEmpty()) {
//                        if (loadBalancerConfiguration.getDefaultDomain().isPresent()) {
//                            filenames.add(String.format(template.getFilename(), loadBalancerConfiguration.getDefaultDomain().get(), service.getServiceId()));
//                        } else {
//                            throw new IllegalStateException("No domain served for template file that requires domain");
//                        }
//                    }
//                } else if (loadBalancerConfiguration.getDefaultDomain().isPresent()) {
//                    filenames.add(String.format(template.getFilename(), loadBalancerConfiguration.getDefaultDomain().get(), service.getServiceId()));
//                } else {
//                    throw new IllegalStateException("No domain present for template file that requires domain");
//                }
//                return filenames;
//        }
    }

    private boolean isDomainServed(String domain) {
        return loadBalancerConfiguration.getDomains().contains(domain) || (loadBalancerConfiguration.getDefaultDomain().isPresent() && domain.equals(loadBalancerConfiguration.getDefaultDomain().get()));
    }


    private static String handlebars(String javascript, Object context) {
        Handlebars handlebars = new Handlebars(null);
        try {
            Template template = handlebars.compileInline(javascript);
            return template.apply(context);
        } catch (IOException e) {
            e.printStackTrace();
            return javascript;
        }
    }

    public static void main(String[] args) {
        BaragonService service = new BaragonService("node", Collections.EMPTY_LIST, null, Collections.emptySet(), Collections.singletonMap("domain", "test"));
        System.out.println(handlebars("proxy/{{{service.options.domain}}}/{{{service.serviceId}}}.conf", Collections.singletonMap("service", service)));
    }
}
