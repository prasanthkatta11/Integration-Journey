public class WhatsAppRestWrapperClass {
  public entry[] entry;
  public class entry {
    public String id;
    public changes[] changes;
  }

  public class changes {
    public value value;
    public String field;
  }

  public class value {
    public String messaging_product;
    public metadata metadata;
    public contacts[] contacts;
    public messages[] messages;
  }

  public class metadata {
    public String display_phone_number;
    public String phone_number_id;
  }

  public class contacts {
    public profile profile;
    public String wa_id;
  }

  public class profile {
    public String name;
  }

  public class messages {
    public context context;
    public String fromx;
    public String id;
    public String timestamp;
    public text text;
    public String typex;
    public image image;
    public image video;
  }

  public class context {
    public String fromx;
    public String id;
  }

  public class text {
    public String body;
  }

  public class image {
    public String mime_type;
    public String id;
    public String sha256;
  }
}
