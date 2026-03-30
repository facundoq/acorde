import { Text, TextProps } from './Themed';
import { Typography } from '@/constants/Typography';

export function MonoText(props: TextProps) {
  return (
    <Text 
      {...props} 
      style={[
        props.style, 
        { 
          ...Typography.mono as any
        }
      ]} 
    />
  );
}
